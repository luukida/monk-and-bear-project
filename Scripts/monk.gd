extends CharacterBody2D

@export_group("Stats")
@export var speed = 150.0
@export var max_hp = 100.0
@export var invulnerability_duration: float = 1.0

@export_group("Visual")
@export var heal_animation_name: String = "healVFX" 

@export_group("EXP Gem Collect")
@export var magnet_radius: float = 100.0

@export_group("Skill 1: Mel Sagrado")
@export var honey_cooldown_time = 5.0
@export var honey_throw_range = 300.0

var honey_current_cooldown = 0.0
var honey_projectile_scene = preload("res://Scenes/Skills/honey_pot_projectile.tscn")

@export_group("Audio")
@export var footstep_sounds: Array[AudioStream] = [] 
@export var footstep_interval: float = 0.18

var current_step_timer: float = 0.0

# ESTADOS
var current_hp = max_hp
var is_invincible = false
var is_aiming_skill_1 = false 

# --- HEAL OVER TIME VARIABLES ---
var heal_timer: float = 0.0
var heal_rate: float = 0.0

# FÍSICA
var external_velocity: Vector2 = Vector2.ZERO
var bear_node: CharacterBody2D = null

# REFERÊNCIAS
@onready var sprite = $AnimatedSprite2D
@onready var hp_bar = $HpBar     
@onready var aim_indicator = $AbilityIndicator 
@onready var heal_vfx = $HealVFX
@onready var magnet_area = $MagnetArea/CollisionShape2D
@onready var footstep_player = $FootstepPlayer

func _ready():
	add_to_group("player")
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	
	if aim_indicator: aim_indicator.visible = false
	if heal_vfx: heal_vfx.visible = false
	
	# Update Magnet Size
	if magnet_area:
		magnet_area.shape.radius = magnet_radius

func _physics_process(delta):
	# 1. Process Cooldowns
	if honey_current_cooldown > 0:
		honey_current_cooldown -= delta
	update_hud_cooldowns()

	# 2. Process Heal Over Time (HoT)
	if heal_timer > 0:
		heal_timer -= delta
		
		# Apply healing per second
		var heal_amount = heal_rate * delta
		current_hp = min(current_hp + heal_amount, max_hp)
		hp_bar.value = current_hp
		
		# Ensure VFX is playing
		if heal_vfx and not heal_vfx.visible:
			_start_vfx_loop()
			
		# Cleanup when finished
		if heal_timer <= 0:
			_stop_vfx_loop()

	# 3. Input States
	if is_aiming_skill_1:
		handle_aiming_logic(delta)
	else:
		handle_movement_logic(delta)
		handle_skill_activation()

	move_and_slide()

# --- HEAL LOGIC ---

func start_heal_over_time(total_amount: float, duration: float):
	heal_timer = duration
	heal_rate = total_amount / duration
	
	# Visual Feedback (Green Tint)
	if not is_invincible:
		sprite.modulate = Color(0.7, 1.0, 0.7)

func _start_vfx_loop():
	if heal_vfx:
		heal_vfx.visible = true
		# Force looping to TRUE so it plays continuously
		heal_vfx.sprite_frames.set_animation_loop(heal_animation_name, true)
		heal_vfx.play(heal_animation_name)

func _stop_vfx_loop():
	if heal_vfx:
		heal_vfx.visible = false
		heal_vfx.stop()
	# Restore color
	sprite.modulate = Color.WHITE

# --- MOVEMENT & SKILLS (Unchanged) ---

func handle_movement_logic(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var player_velocity = input_dir * speed
	velocity = player_velocity + external_velocity
	external_velocity = external_velocity.move_toward(Vector2.ZERO, 300 * delta)
	
	if input_dir.length() > 0:
		sprite.play("run")
		if input_dir.x != 0: 
			sprite.flip_h = input_dir.x < 0
			
		handle_footsteps(delta)
	else:
		sprite.play("idle")

func apply_rope_pull(pull_vector: Vector2):
	external_velocity = pull_vector

func handle_skill_activation():
	if Input.is_action_just_pressed("skill_1"):
		if honey_current_cooldown <= 0:
			start_aiming()
		else:
			print("Skill Cooldown!")

func start_aiming():
	is_aiming_skill_1 = true
	if aim_indicator: aim_indicator.visible = true

func cancel_aiming():
	is_aiming_skill_1 = false
	if aim_indicator: aim_indicator.visible = false

func handle_aiming_logic(delta):
	handle_movement_logic(delta)
	var mouse_pos = get_global_mouse_position()
	var dist = global_position.distance_to(mouse_pos)
	var dir = global_position.direction_to(mouse_pos)
	var target_pos = mouse_pos
	if dist > honey_throw_range:
		target_pos = global_position + (dir * honey_throw_range)
	
	if aim_indicator: aim_indicator.global_position = target_pos
	
	if Input.is_action_just_pressed("mouse_left"):
		cast_honey_pot(target_pos)
		cancel_aiming()
	if Input.is_action_just_pressed("mouse_right") or Input.is_action_just_pressed("skill_1"):
		cancel_aiming()

func cast_honey_pot(target_pos):
	honey_current_cooldown = honey_cooldown_time
	if honey_projectile_scene:
		var pot = honey_projectile_scene.instantiate()
		get_tree().current_scene.add_child(pot)
		pot.launch(global_position, target_pos)

func update_hud_cooldowns():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_skill_cooldowns"):
		hud.update_skill_cooldowns(honey_current_cooldown, honey_cooldown_time)

func take_damage(amount):
	if is_invincible: return
	
	current_hp -= amount
	hp_bar.value = current_hp
	
	if current_hp <= 0:
		print("GAME OVER")
		
		# --- GET CURRENT WAVE ---
		# We try to find the WaveManager to know which wave we are on.
		var current_wave = 1
		var wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")
		if wave_manager:
			# wave_index is 0-based, so +1 for display
			current_wave = wave_manager.current_wave_index + 1
		
		# Trigger the Global Game Over
		GameManager.trigger_game_over(current_wave)
		return

	is_invincible = true
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	for i in range(5):
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.5), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.finished.connect(func(): is_invincible = false)

# --- MAGNET LOGIC ---
# Connect this function to the "area_entered" signal of your MagnetArea
func _on_magnet_area_entered(area):
	# Check if the area is an XP Gem
	if area.has_method("start_magnet"):
		area.start_magnet(self)

func handle_footsteps(delta):
	if footstep_sounds.is_empty(): return
	
	current_step_timer -= delta
	
	if current_step_timer <= 0:
		play_random_footstep()
		current_step_timer = footstep_interval

func play_random_footstep():
	if not footstep_player: return
	
	# Pick a random sound from the list
	var random_sound = footstep_sounds.pick_random()
	footstep_player.stream = random_sound
	
	# Randomize pitch slightly for variety
	footstep_player.pitch_scale = randf_range(0.9, 1.1)
	
	footstep_player.play()
