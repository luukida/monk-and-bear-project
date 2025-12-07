extends CharacterBody2D

enum State { FOLLOW, CHASE, ATTACK, DOWNED, FRENZY, PREPARE }
var current_state = State.FOLLOW

@export_group("Stats")
@export var move_speed = 180.0
@export var max_hp = 200.0
@export var damage = 35.0
@export var auto_revive_time: float = 10.0

# --- CHASE LIMITS (Parallel) ---
@export var chase_give_up_range: float = 400.0 
@export var chase_max_duration: float = 2.0    

@export_group("Combat & Frenzy")
@export var attack_speed: float = 1.0 
@export var base_telegraph_duration: float = 0.5 
@export var frenzy_speed_multiplier: float = 1.5 
@export var frenzy_damage_multiplier: float = 2.0 
@export var frenzy_range_multiplier: float = 1.5
@export var frenzy_switch_target_time: float = 2.0

@export_group("Visual")
@export var max_rotation_degrees: float = 30.0 
@export var attack_impact_frame: int = 6 
@export var heal_animation_name: String = "healVFX" 

@export_group("Audio")
@export var footstep_sounds: Array[AudioStream] = [] 
@export var footstep_interval: float = 0.25 
@export var quadruped_delay: float = 0.20 # Time between front and back paw hits
@export var attack_sound: AudioStream

var current_step_timer: float = 0.0

# --- VARIABLES ---
var current_hp = max_hp
var is_downed = false
var is_invincible = false 
var is_frenzy_active = false 

var target_enemy: Node2D = null
var monk_node: Node2D = null

var is_chasing_honey = false
var honey_target_pos: Vector2 = Vector2.ZERO
var heal_timer: float = 0.0
var heal_rate: float = 0.0

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
var current_chase_timer: float = 0.0 

var wander_timer: float = 0.0
var wander_target: Vector2 = Vector2.ZERO
var is_wandering: bool = false

# --- NODES ---
@onready var sprite = $AnimatedSprite2D
@onready var body_shape = $CollisionShape2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea 
@onready var attack_shape = $AttackArea/CollisionShape2D
@onready var hp_bar = $HpBar 
@onready var heal_vfx = $HealVFX
@onready var revive_label = $ReviveLabel
@onready var telegraph = $AttackArea/TelegraphSprite
@onready var attack_player = $AttackSoundPlayer
@onready var footstep_player = $FootstepPlayer

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
	
	if heal_vfx: heal_vfx.visible = false
	
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

	if heal_timer > 0:
		heal_timer -= delta
		var heal_amount = heal_rate * delta
		current_hp = min(current_hp + heal_amount, max_hp)
		hp_bar.value = current_hp
		
		if heal_vfx and not heal_vfx.visible:
			_start_vfx_loop()
			
		if heal_timer <= 0:
			_stop_vfx_loop()

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
	
	# If the bear is trying to move, play sounds
	if velocity.length() > 0:
		handle_footsteps(delta)
	else:
		current_step_timer = 0.0
	
	move_and_slide()

# --- BEHAVIORS ---

func behavior_follow(delta):
	if not is_instance_valid(monk_node): return
	
	if is_chasing_honey:
		var dist = global_position.distance_to(honey_target_pos)
		if dist > 20.0:
			var dir = global_position.direction_to(honey_target_pos)
			velocity = dir * move_speed 
			sprite.play("run")
			update_orientation(honey_target_pos)
		else:
			velocity = Vector2.ZERO
			sprite.play("idle")
			stop_eating_honey()
		return 
	
	scan_for_enemies()
	if is_instance_valid(target_enemy):
		current_state = State.CHASE
		return
	
	behavior_roam_logic(delta, false)

func behavior_chase():
	if is_chasing_honey:
		current_state = State.FOLLOW
		return

	if not is_instance_valid(target_enemy):
		current_state = State.FOLLOW
		return
	
	var delta = get_physics_process_delta_time()
	current_chase_timer -= delta
	
	if current_chase_timer <= 0 and sprite.animation != "attack":
		target_enemy = null
		current_state = State.FOLLOW
		return

	var dist_target = global_position.distance_to(target_enemy.global_position)
	if dist_target > chase_give_up_range:
		target_enemy = null 
		current_state = State.FOLLOW 
		return
		
	if attack_area.overlaps_body(target_enemy) or dist_target < 60.0:
		start_attack()
	else:
		var dir = global_position.direction_to(target_enemy.global_position)
		velocity = dir * (move_speed * 1.2)
		sprite.play("run")
		update_orientation(target_enemy.global_position)

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

# --- AUDIO LOGIC ---

func play_attack_sound():
	if not attack_player or not attack_sound: return
	
	# --- LOGIC UPDATE: Frenzy = 100% Volume ---
	# Only roll the dice if we are NOT in frenzy mode.
	if not is_frenzy_active:
		# 40% Chance (If random is > 0.4, we skip)
		if randf() > 0.4: 
			return 
	
	attack_player.stream = attack_sound
	attack_player.pitch_scale = randf_range(0.8, 1.2)
	attack_player.play()

# --- OTHER LOGIC ---

func detect_honey(honey_position: Vector2):
	if is_downed or is_frenzy_active: return
	is_chasing_honey = true
	honey_target_pos = honey_position
	current_state = State.FOLLOW
	target_enemy = null 

func stop_eating_honey():
	if is_chasing_honey:
		is_chasing_honey = false
		wander_timer = 1.0 

func start_heal_over_time(total_amount: float, duration: float):
	if is_downed: return
	heal_timer = duration
	heal_rate = total_amount / duration
	if not is_frenzy_active:
		sprite.modulate = Color(0.7, 1.0, 0.7)

func _start_vfx_loop():
	if heal_vfx:
		heal_vfx.visible = true
		heal_vfx.sprite_frames.set_animation_loop(heal_animation_name, true)
		heal_vfx.play(heal_animation_name)

func _stop_vfx_loop():
	if heal_vfx:
		heal_vfx.visible = false
		heal_vfx.stop()
	if not is_frenzy_active and not is_downed:
		sprite.modulate = Color.WHITE

func heal_self(amount):
	start_heal_over_time(amount, 2.0)

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
		current_chase_timer = chase_max_duration

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

func start_attack():
	if is_frenzy_active:
		start_telegraph()
	else:
		execute_attack_animation()

func start_telegraph():
	if is_instance_valid(target_enemy):
		update_orientation(target_enemy.global_position)
	
	var actual_duration = base_telegraph_duration / attack_speed
	if is_frenzy_active: actual_duration = 0.0 
	
	if actual_duration <= 0.05:
		execute_attack_animation()
		return
		
	current_state = State.PREPARE
	sprite.play("idle")
	
	if telegraph:
		telegraph.visible = true
		var tween = create_tween()
		telegraph.modulate.a = 0.0
		tween.tween_property(telegraph, "modulate:a", 0.8, actual_duration)
	
	await get_tree().create_timer(actual_duration).timeout
	
	if current_state == State.PREPARE:
		execute_attack_animation()

func execute_attack_animation():
	current_state = State.ATTACK
	
	if is_frenzy_active and telegraph:
		telegraph.visible = true 
	elif telegraph:
		telegraph.visible = false 
		
	damage_dealt_this_attack = false
	sprite.play("attack")
	sprite.frame = 0 
	sprite.speed_scale = attack_speed
	if is_frenzy_active: sprite.speed_scale *= 1.5
	
	# PLAY SOUND!
	play_attack_sound()
	
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
			if body.is_in_group("enemy") or body.is_in_group("player"): hit_valid = true
		else:
			if body.is_in_group("enemy"): hit_valid = true
		if hit_valid and body.has_method("take_damage"):
			body.take_damage(damage)

func _on_animation_finished():
	if sprite.animation == "attack":
		if not damage_dealt_this_attack: apply_damage_snapshot()
		sprite.speed_scale = 1.0 
		if is_frenzy_active:
			current_state = State.FRENZY
			target_enemy = null 
			scan_for_enemies() 
		else:
			current_state = State.FOLLOW

func enter_frenzy():
	if is_downed: return
	if is_frenzy_active: return
	is_frenzy_active = true
	current_state = State.FRENZY
	move_speed = base_speed * frenzy_speed_multiplier
	damage = base_damage * frenzy_damage_multiplier
	attack_area.scale = base_attack_scale * frenzy_range_multiplier
	detection_area.scale = base_detection_scale * frenzy_range_multiplier
	chase_give_up_range = base_chase_give_up_range * frenzy_range_multiplier * 1.2
	var current_alpha = sprite.modulate.a
	sprite.modulate = Color(2.0, 0.2, 0.2, current_alpha)
	target_enemy = null
	current_frenzy_chase_timer = 0.0
	scan_for_enemies()

func exit_frenzy():
	if not is_frenzy_active: return
	is_frenzy_active = false
	current_state = State.FOLLOW
	move_speed = base_speed
	damage = base_damage
	attack_area.scale = base_attack_scale
	detection_area.scale = base_detection_scale
	chase_give_up_range = base_chase_give_up_range
	var current_alpha = sprite.modulate.a
	sprite.modulate = Color(1, 1, 1, current_alpha)
	if telegraph: telegraph.visible = false

func take_damage(amount):
	if is_downed or is_invincible: return
	current_hp -= amount
	hp_bar.value = current_hp
	if current_hp <= 0:
		go_down()
	else:
		var return_color = Color(2, 0.2, 0.2) if is_frenzy_active else Color.WHITE
		sprite.modulate = Color.RED
		var tween = create_tween()
		var target_color = return_color
		target_color.a = sprite.modulate.a
		tween.tween_property(sprite, "modulate", target_color, 0.1)

func go_down():
	if is_frenzy_active: exit_frenzy()
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

func revive_complete():
	is_downed = false
	current_hp = max_hp
	body_shape.set_deferred("disabled", false)
	hp_bar.value = current_hp
	hp_bar.visible = true
	revive_label.visible = false
	sprite.modulate = Color.WHITE
	is_invincible = true
	var blink_tween = create_tween()
	for i in range(10): 
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

func push_enemies_away():
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and body.has_method("apply_knockback"):
			var push_dir = global_position.direction_to(body.global_position)
			var push_force = 150.0
			body.apply_knockback(push_dir * push_force)
			if body.has_method("take_damage"):
				body.take_damage(15)

func handle_footsteps(delta):
	if footstep_sounds.is_empty(): return
	
	current_step_timer -= delta
	
	if current_step_timer <= 0:
		# 1. Play First Paw (Front)
		play_random_footstep()
		
		# 2. Schedule Second Paw (Back) with a tiny delay
		# We use a Tween here to create a "one-shot" timer without adding complex logic
		var step_tween = create_tween()
		step_tween.tween_callback(play_random_footstep).set_delay(quadruped_delay)
		
		# 3. Reset Timer logic (Same as before)
		var next_interval = footstep_interval
		
		if current_state == State.FRENZY:
			next_interval = footstep_interval / frenzy_speed_multiplier
		elif current_state == State.CHASE:
			next_interval = footstep_interval / 1.2
			
		current_step_timer = next_interval

func play_random_footstep():
	if not footstep_player: return
	
	var random_sound = footstep_sounds.pick_random()
	footstep_player.stream = random_sound
	# Lower pitch for the Bear to sound heavier/bigger than the Monk
	footstep_player.pitch_scale = randf_range(0.7, 0.9)
	footstep_player.play()
