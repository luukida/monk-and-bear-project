extends CharacterBody2D

enum State { FOLLOW, CHASE, ATTACK, DOWNED, FRENZY, PREPARE }
var current_state = State.FOLLOW

@export_group("Stats")
@export var move_speed = 180.0
@export var max_hp = 200.0
@export var damage = 35.0
@export var auto_revive_time: float = 10.0
@export var chase_give_up_range: float = 400.0 

@export_group("Berserk Stats")
@export var frenzy_speed_multiplier: float = 1.5 
@export var frenzy_damage_multiplier: float = 2.0 
@export var frenzy_range_multiplier: float = 1.5
@export var frenzy_switch_target_time: float = 2.0
@export var telegraph_duration: float = 0.0 

@export_group("Visual")
@export var max_rotation_degrees: float = 30.0 
@export var attack_impact_frame: int = 6 
@export var heal_animation_name: String = "healVFX" 

var current_hp = max_hp
var is_downed = false
var is_invincible = false 
var is_frenzy_active = false 

var target_enemy: Node2D = null
var monk_node: Node2D = null

# Variáveis Internas
var default_shape_x: float = 0.0
var default_telegraph_x: float = 0.0
var current_revive_timer: float = 0.0
var base_speed: float = 0.0
var base_damage: float = 0.0
var base_attack_scale: Vector2 = Vector2.ONE 
var base_detection_scale: Vector2 = Vector2.ONE
var base_chase_give_up_range: float = 0.0

var damage_dealt_this_attack: bool = false
var current_frenzy_chase_timer: float = 0.0

var wander_timer: float = 0.0
var wander_target: Vector2 = Vector2.ZERO
var is_wandering: bool = false

@onready var sprite = $AnimatedSprite2D
@onready var body_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea 
@onready var attack_shape = $AttackArea/CollisionShape2D
@onready var hp_bar = $HpBar 
@onready var heal_vfx = $HealVFX
@onready var revive_label = $ReviveLabel
@onready var telegraph = $AttackArea/TelegraphSprite

func _ready():
	add_to_group("bear")
	
	base_speed = move_speed
	base_damage = damage
	base_attack_scale = attack_area.scale
	base_detection_scale = detection_area.scale
	base_chase_give_up_range = chase_give_up_range
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	
	default_shape_x = attack_shape.position.x
	
	if telegraph:
		default_telegraph_x = telegraph.position.x
		telegraph.visible = false
	
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	
	if not heal_vfx.animation_finished.is_connected(_on_vfx_finished):
		heal_vfx.animation_finished.connect(_on_vfx_finished)
	heal_vfx.visible = false
	revive_label.visible = false 
	
	detection_area.monitoring = true
	detection_area.monitorable = false
	attack_area.monitoring = true
	attack_area.monitorable = false

func _process(delta):
	if is_downed:
		current_revive_timer -= delta
		revive_label.text = "%d" % ceil(max(0.0, current_revive_timer))
		if current_revive_timer <= 0:
			revive_complete()

func _physics_process(delta):
	if is_downed: return

	match current_state:
		State.FOLLOW:
			behavior_follow(delta)
		State.CHASE:
			behavior_chase()
		State.FRENZY:
			behavior_frenzy(delta)
		State.PREPARE:
			velocity = Vector2.ZERO 
		State.ATTACK:
			velocity = Vector2.ZERO
			
	move_and_slide()

# --- MODOS E COMPORTAMENTOS ---

func enter_frenzy():
	if is_downed: return
	if is_frenzy_active: return
	
	print("URSO ENTROU EM FRENESI!")
	is_frenzy_active = true
	current_state = State.FRENZY
	
	# Aplica Buffs
	move_speed = base_speed * frenzy_speed_multiplier
	damage = base_damage * frenzy_damage_multiplier
	
	attack_area.scale = base_attack_scale * frenzy_range_multiplier
	detection_area.scale = base_detection_scale * frenzy_range_multiplier
	chase_give_up_range = base_chase_give_up_range * frenzy_range_multiplier * 1.2
	
	# CORREÇÃO: Aplica cor vermelha mas PRESERVA o alpha (se estiver piscando)
	var current_alpha = sprite.modulate.a
	sprite.modulate = Color(2.0, 0.2, 0.2, current_alpha)
	
	target_enemy = null
	current_frenzy_chase_timer = 0.0
	scan_for_enemies()

func exit_frenzy():
	if not is_frenzy_active: return
	print("Urso se acalmou.")
	is_frenzy_active = false
	current_state = State.FOLLOW
	
	# Restaura
	move_speed = base_speed
	damage = base_damage
	attack_area.scale = base_attack_scale
	detection_area.scale = base_detection_scale
	chase_give_up_range = base_chase_give_up_range
	
	# CORREÇÃO: Volta para Branco mas preserva alpha
	var current_alpha = sprite.modulate.a
	sprite.modulate = Color(1, 1, 1, current_alpha)
	
	if telegraph: telegraph.visible = false

func behavior_frenzy(delta):
	if not is_instance_valid(target_enemy):
		scan_for_enemies()
		if not is_instance_valid(target_enemy):
			behavior_roam_logic(delta, true)
			return

	current_frenzy_chase_timer += delta
	if current_frenzy_chase_timer > frenzy_switch_target_time:
		current_frenzy_chase_timer = 0.0
		scan_for_enemies() 
		if target_enemy == null: return

	var dist = global_position.distance_to(target_enemy.global_position)
	if dist > chase_give_up_range:
		target_enemy = null 
		scan_for_enemies() 
		return

	if attack_area.overlaps_body(target_enemy) or dist < 60.0:
		current_frenzy_chase_timer = 0.0
		start_attack()
	else:
		var dir = global_position.direction_to(target_enemy.global_position)
		velocity = dir * move_speed
		sprite.play("run")
		update_orientation(target_enemy.global_position)

func behavior_follow(delta):
	if not is_instance_valid(monk_node): return
	
	scan_for_enemies()
	if is_instance_valid(target_enemy):
		current_state = State.CHASE
		return
	
	behavior_roam_logic(delta, false)

func behavior_roam_logic(delta, is_frenzy_mode):
	if wander_timer > 0:
		wander_timer -= delta
		velocity = Vector2.ZERO
		sprite.play("idle")
		sprite.rotation = move_toward(sprite.rotation, 0, 0.1)
		attack_area.rotation = sprite.rotation
	else:
		if not is_wandering:
			var random_angle = randf() * TAU
			var random_dist = randf_range(100.0, 300.0) 
			wander_target = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_dist
			is_wandering = true
		
		var dir = global_position.direction_to(wander_target)
		var dist_to_target = global_position.distance_to(wander_target)
		
		var speed_factor = 1.0 if is_frenzy_mode else 0.4
		velocity = dir * (move_speed * speed_factor)
		sprite.play("run")
		update_orientation(wander_target)
		
		if dist_to_target < 10.0:
			is_wandering = false
			wander_timer = randf_range(0.5, 1.0) if is_frenzy_mode else randf_range(2.0, 4.0)

func behavior_chase():
	if not is_instance_valid(target_enemy):
		current_state = State.FOLLOW
		return
	
	var dist = global_position.distance_to(target_enemy.global_position)
	if dist > chase_give_up_range:
		target_enemy = null 
		current_state = State.FOLLOW 
		return
		
	if attack_area.overlaps_body(target_enemy):
		start_attack()
	else:
		var dir = global_position.direction_to(target_enemy.global_position)
		velocity = dir * (move_speed * 1.2)
		sprite.play("run")
		update_orientation(target_enemy.global_position)

func scan_for_enemies():
	var bodies = detection_area.get_overlapping_bodies()
	var valid_targets = []
	
	for body in bodies:
		if is_frenzy_active:
			if body.is_in_group("enemy") or body.is_in_group("player"):
				valid_targets.append(body)
		else:
			if body.is_in_group("enemy"):
				valid_targets.append(body)
			
	if valid_targets.is_empty():
		target_enemy = null
		return

	if is_frenzy_active:
		var potential_target = valid_targets.pick_random()
		if potential_target == target_enemy and valid_targets.size() > 1:
			valid_targets.erase(potential_target)
			potential_target = valid_targets.pick_random()
		target_enemy = potential_target
	else:
		var closest_dist = INF
		var closest_enemy = null
		for enemy in valid_targets:
			var dist = global_position.distance_squared_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = enemy
		
		target_enemy = closest_enemy

# --- ORIENTAÇÃO ---

func update_orientation(target_pos: Vector2):
	var dir = global_position.direction_to(target_pos)
	
	if dir.x != 0:
		sprite.flip_h = dir.x < 0
		if dir.x < 0:
			attack_shape.position.x = -default_shape_x
			if telegraph: telegraph.position.x = -default_telegraph_x
		else:
			attack_shape.position.x = default_shape_x
			if telegraph: telegraph.position.x = default_telegraph_x

	var rotation_angle = 0.0
	if dir.x < 0:
		rotation_angle = atan2(dir.y, -dir.x)
		rotation_angle = -rotation_angle 
	else:
		rotation_angle = atan2(dir.y, dir.x)
	
	var max_rad = deg_to_rad(max_rotation_degrees)
	rotation_angle = clamp(rotation_angle, -max_rad, max_rad)
	
	sprite.rotation = rotation_angle
	attack_area.rotation = rotation_angle

# --- COMBATE ---

func start_attack():
	if is_frenzy_active:
		start_telegraph()
	else:
		execute_attack_animation()

func start_telegraph():
	if is_instance_valid(target_enemy):
		update_orientation(target_enemy.global_position)
	
	if telegraph_duration <= 0.05:
		execute_attack_animation()
		return

	current_state = State.PREPARE
	sprite.play("idle")
	
	if telegraph:
		telegraph.visible = true
		var tween = create_tween()
		telegraph.modulate.a = 0.0
		tween.tween_property(telegraph, "modulate:a", 0.8, telegraph_duration)
		
	await get_tree().create_timer(telegraph_duration).timeout
	
	if current_state == State.PREPARE:
		execute_attack_animation()

func execute_attack_animation():
	current_state = State.ATTACK
	
	if is_frenzy_active and telegraph:
		telegraph.visible = true
		if telegraph_duration <= 0.05:
			telegraph.modulate.a = 0.0
			var tween = create_tween()
			tween.tween_property(telegraph, "modulate:a", 0.8, 0.3)
		else:
			telegraph.modulate.a = 0.8
	elif telegraph:
		telegraph.visible = false 
	
	damage_dealt_this_attack = false
	sprite.play("attack")
	sprite.frame = 0 
	
	if not is_frenzy_active and is_instance_valid(target_enemy):
		update_orientation(target_enemy.global_position)

func _on_frame_changed():
	if sprite.animation == "attack" and sprite.frame == attack_impact_frame:
		if telegraph: telegraph.visible = false
		apply_damage_snapshot()

func apply_damage_snapshot():
	if damage_dealt_this_attack: return 
	damage_dealt_this_attack = true
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		var hit_valid = false
		if is_frenzy_active:
			if body.is_in_group("enemy") or body.is_in_group("player"):
				hit_valid = true
		else:
			if body.is_in_group("enemy"):
				hit_valid = true
		
		if hit_valid and body.has_method("take_damage"):
			body.take_damage(damage)

func _on_animation_finished():
	if sprite.animation == "attack":
		if not damage_dealt_this_attack:
			apply_damage_snapshot()
		
		if is_frenzy_active:
			current_state = State.FRENZY
			target_enemy = null 
			scan_for_enemies() 
		else:
			current_state = State.FOLLOW

# --- VIDA, MORTE, REVIVE ---

func take_damage(amount):
	if is_downed or is_invincible: return
	current_hp -= amount
	hp_bar.value = current_hp
	if current_hp <= 0:
		go_down()
	else:
		# Efeito de Dano (Vermelho)
		var base_color = Color(2, 0.2, 0.2) if is_frenzy_active else Color.WHITE
		
		sprite.modulate = Color.RED
		var tween = create_tween()
		# Retorna para a cor correta mas PRESERVANDO O ALPHA ATUAL
		var target_color = base_color
		target_color.a = sprite.modulate.a 
		
		tween.tween_property(sprite, "modulate", target_color, 0.1)

func go_down():
	if is_frenzy_active:
		exit_frenzy()
	is_downed = true
	current_state = State.DOWNED
	target_enemy = null
	body_shape.set_deferred("disabled", true)
	hp_bar.visible = false
	
	if telegraph: telegraph.visible = false
	
	current_revive_timer = auto_revive_time
	revive_label.visible = true
	revive_label.text = str(int(auto_revive_time))
	
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.5) 
	sprite.rotation = 0
	sprite.play("death")
	print("Urso Caiu!")

func revive_complete():
	is_downed = false
	current_hp = max_hp
	body_shape.set_deferred("disabled", false)
	hp_bar.value = current_hp
	hp_bar.visible = true
	revive_label.visible = false
	sprite.modulate = Color.WHITE
	is_invincible = true
	
	print("Urso Revivido!")
	
	# TWEEN DE INVENCIBILIDADE (Piscar Alpha apenas)
	var blink_tween = create_tween()
	for i in range(10): 
		# Pisca a Transparência (Alpha), não mexe na cor
		blink_tween.tween_property(sprite, "modulate:a", 0.5, 0.15)
		blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.15)
	blink_tween.finished.connect(func(): is_invincible = false)
	
	push_enemies_away()
	await get_tree().create_timer(0.1).timeout
	scan_for_enemies()
	
	if is_instance_valid(target_enemy):
		current_state = State.CHASE
	else:
		current_state = State.FOLLOW
		sprite.play("idle")

# --- UTILS ---

func receive_heal_tick(amount):
	if is_downed: return 
	current_hp = min(current_hp + amount, max_hp)
	hp_bar.value = current_hp
	play_continuous_heal_vfx()
	
	# Tintura Verde apenas se não estiver em Frenesi
	if not is_frenzy_active:
		# Aplica verde preservando alpha
		var current_alpha = sprite.modulate.a
		sprite.modulate = Color(0.7, 1.0, 0.7, current_alpha)

func play_continuous_heal_vfx():
	if heal_vfx:
		heal_vfx.visible = true
		if not heal_vfx.is_playing() or heal_vfx.animation != heal_animation_name:
			heal_vfx.play(heal_animation_name)

func stop_heal_vfx():
	if heal_vfx:
		heal_vfx.visible = false
		heal_vfx.stop()
	
	if not is_downed:
		# Restaura cor base preservando alpha
		var current_alpha = sprite.modulate.a
		if is_frenzy_active:
			sprite.modulate = Color(2.0, 0.2, 0.2, current_alpha)
		else:
			sprite.modulate = Color(1, 1, 1, current_alpha)

func _on_vfx_finished(): pass 

func push_enemies_away():
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and body.has_method("apply_knockback"):
			var push_dir = global_position.direction_to(body.global_position)
			var push_force = 150.0
			body.apply_knockback(push_dir * push_force)
			if body.has_method("take_damage"):
				body.take_damage(15)
