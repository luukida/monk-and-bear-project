extends CharacterBody2D

enum State { FOLLOW, CHASE, ATTACK, DOWNED }
var current_state = State.FOLLOW

@export_group("Stats")
@export var move_speed = 180.0
@export var max_hp = 200.0
@export var damage = 35.0
@export var auto_revive_time: float = 10.0

@export_group("Visual")
@export var max_rotation_degrees: float = 30.0 
@export var attack_impact_frame: int = 6 # Mantido seu valor 6
@export var heal_animation_name: String = "healVFX" 

var current_hp = max_hp
var is_downed = false
var is_invincible = false 
var target_enemy: Node2D = null
var monk_node: Node2D = null

var default_shape_x: float = 0.0
var current_revive_timer: float = 0.0

@onready var sprite = $AnimatedSprite2D
# REFERÊNCIA NOVA: O colisor do CORPO do urso (para desligar quando morrer)
@onready var body_shape = $CollisionShape2D

@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea 
@onready var attack_shape = $AttackArea/CollisionShape2D
@onready var hp_bar = $HpBar 
@onready var heal_vfx = $HealVFX
@onready var revive_label = $ReviveLabel

func _ready():
	add_to_group("bear")
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	
	default_shape_x = attack_shape.position.x
	
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
			behavior_follow()
		State.CHASE:
			behavior_chase()
		State.ATTACK:
			velocity = Vector2.ZERO
			
	move_and_slide()

# --- IA ---

func behavior_follow():
	if not is_instance_valid(monk_node): return
	
	scan_for_enemies()
	if is_instance_valid(target_enemy):
		current_state = State.CHASE
		return
	
	var dist = global_position.distance_to(monk_node.global_position)
	
	if dist > 80.0:
		var dir = global_position.direction_to(monk_node.global_position)
		velocity = dir * move_speed
		sprite.play("run")
		update_orientation(monk_node.global_position)
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")
		sprite.rotation = move_toward(sprite.rotation, 0, 0.1)
		attack_area.rotation = sprite.rotation

func behavior_chase():
	if not is_instance_valid(target_enemy):
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
	var closest_dist = INF
	var closest_enemy = null
	
	for body in bodies:
		if body.is_in_group("enemy"):
			var dist = global_position.distance_squared_to(body.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = body
	
	if closest_enemy:
		target_enemy = closest_enemy

# --- ORIENTAÇÃO ---

func update_orientation(target_pos: Vector2):
	var dir = global_position.direction_to(target_pos)
	
	if dir.x != 0:
		sprite.flip_h = dir.x < 0
		if dir.x < 0:
			attack_shape.position.x = -default_shape_x
		else:
			attack_shape.position.x = default_shape_x

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
	current_state = State.ATTACK
	sprite.play("attack")
	sprite.frame = 0 
	if is_instance_valid(target_enemy):
		update_orientation(target_enemy.global_position)

func _on_frame_changed():
	if sprite.animation == "attack" and sprite.frame == attack_impact_frame:
		apply_damage_snapshot()

func apply_damage_snapshot():
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage)

func _on_animation_finished():
	if sprite.animation == "attack":
		current_state = State.CHASE

# --- VIDA, MORTE ---

func take_damage(amount):
	if is_downed or is_invincible: return
	
	current_hp -= amount
	hp_bar.value = current_hp
	
	if current_hp <= 0:
		go_down()
	else:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func go_down():
	is_downed = true
	current_state = State.DOWNED
	target_enemy = null
	
	# AQUI: Desliga a colisão do corpo físico para inimigos atravessarem
	# Usamos set_deferred para evitar erros de física durante o frame
	body_shape.set_deferred("disabled", true)
	
	hp_bar.visible = false
	
	current_revive_timer = auto_revive_time
	revive_label.visible = true
	revive_label.text = str(int(auto_revive_time))
	
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.5) 
	
	sprite.rotation = 0
	sprite.play("death")
	print("Urso Caiu! Fantasma ativado.")

# --- AUTO-REVIVE ---

func revive_complete():
	is_downed = false
	current_hp = max_hp
	
	# AQUI: Liga a colisão de volta
	body_shape.set_deferred("disabled", false)
	
	hp_bar.value = current_hp
	hp_bar.visible = true
	revive_label.visible = false
	
	sprite.modulate = Color.WHITE
	
	is_invincible = true
	print("Urso Revivido!")
	
	var blink_tween = create_tween()
	for i in range(10): 
		blink_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.5), 0.15)
		blink_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	blink_tween.finished.connect(func(): is_invincible = false)
	
	# Empurrão com seus valores (150 força, 15 dano)
	push_enemies_away()
	
	await get_tree().create_timer(0.1).timeout
	scan_for_enemies()
	
	if is_instance_valid(target_enemy):
		current_state = State.CHASE
	else:
		current_state = State.FOLLOW
		sprite.play("idle")

# --- CURA E VFX ---

func receive_heal_tick(amount):
	if is_downed: return 
	
	current_hp = min(current_hp + amount, max_hp)
	hp_bar.value = current_hp
	
	play_continuous_heal_vfx()
	sprite.modulate = Color(0.7, 1.0, 0.7) 

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
		sprite.modulate = Color.WHITE

func _on_vfx_finished():
	pass 

func push_enemies_away():
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and body.has_method("apply_knockback"):
			var push_dir = global_position.direction_to(body.global_position)
			var push_force = 150.0
			body.apply_knockback(push_dir * push_force)
			if body.has_method("take_damage"):
				body.take_damage(15)
