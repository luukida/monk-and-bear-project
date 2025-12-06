extends Area2D

@export var xp_value = 1
@export var target_speed = 600.0   
@export var fly_duration = 0.4     

@export_group("Magnet & Recoil")
@export var recoil_speed = -140.0 
@export var recoil_duration = 0.1

@export_group("Visuals")
@export var spawn_shadow_scale: float = 1.05   
@export var initial_shadow_scale: float = 0.5

var target = null
var current_speed = 0.0 
var is_chasing = false

# --- NEW: Track Tweens to cancel them if needed ---
var spread_tween: Tween
var arc_tween: Tween
var shadow_tween: Tween

# References
@onready var sprite = $Sprite2D
@onready var shadow = $SpriteShadow

func _ready():
	body_entered.connect(_on_body_entered)
	play_spawn_animation()

func play_spawn_animation():
	var duration = 0.5
	
	# 1. HORIZONTAL SPREAD
	var random_dir = Vector2.RIGHT.rotated(randf() * TAU)
	var random_dist = randf_range(40.0, 70.0)
	var target_pos = global_position + (random_dir * random_dist)
	
	spread_tween = create_tween()
	spread_tween.tween_property(self, "global_position", target_pos, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. VERTICAL ARC
	sprite.position.y = 0.0 
	var jump_height = -50.0
	
	arc_tween = create_tween()
	# Jump UP
	arc_tween.tween_property(sprite, "position:y", jump_height, duration * 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fall DOWN
	arc_tween.tween_property(sprite, "position:y", 0.0, duration * 0.6)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# 3. SHADOW & ROTATION (Visuals)
	if shadow:
		shadow.scale = Vector2(initial_shadow_scale, initial_shadow_scale)
		shadow_tween = create_tween()
		shadow_tween.tween_property(shadow, "scale", Vector2(spawn_shadow_scale, spawn_shadow_scale), duration)

func _physics_process(delta):
	if is_chasing and is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		position += direction * current_speed * delta

func start_magnet(new_target):
	if is_chasing: return
	
	# --- FIX: KILL SPAWN ANIMATIONS IMMEDIATELY ---
	# If we are picked up mid-air, stop dropping to the floor!
	if spread_tween and spread_tween.is_valid(): spread_tween.kill()
	if arc_tween and arc_tween.is_valid(): arc_tween.kill()
	if shadow_tween and shadow_tween.is_valid(): shadow_tween.kill()
	
	target = new_target
	is_chasing = true
	monitorable = false 
	
	var lift_tween = create_tween()
	lift_tween.set_parallel(true)
	
	# 1. Float Up (Now it works because arc_tween is dead)
	lift_tween.tween_property(sprite, "position", Vector2(0, -20), 0.3)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	# 2. Aerodynamic Tilt
	lift_tween.tween_property(sprite, "rotation_degrees", 36.0, 0.3)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if shadow:
		lift_tween.tween_property(shadow, "rotation_degrees", 36.0, 0.3)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# Shadow Shrink
		lift_tween.tween_property(shadow, "scale", Vector2(0.8, 0.8), 0.3)
	
	# --- MOVEMENT LOGIC ---
	var move_tween = create_tween()
	
	# Recoil
	move_tween.tween_property(self, "current_speed", recoil_speed, recoil_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Chase
	move_tween.tween_property(self, "current_speed", target_speed, fly_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_body_entered(body):
	if body.is_in_group("player"):
		GameManager.gain_xp(xp_value)
		queue_free()
