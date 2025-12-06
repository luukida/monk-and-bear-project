extends Area2D

@export var xp_value = 1
@export var target_speed = 600.0   # Final forward speed
@export var fly_duration = 0.4     # Time to reach max speed after recoil

# --- RECOIL SETTINGS ---
@export var recoil_speed = -130.0  # How fast it flies backward (Negative!)
@export var recoil_duration = 0.1  # How long the recoil lasts

var target = null
var current_speed = 0.0 
var is_chasing = false

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if is_chasing and is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		
		# Moves based on current_speed (which can be negative for recoil)
		position += direction * current_speed * delta

func start_magnet(new_target):
	if is_chasing: return
	
	target = new_target
	is_chasing = true
	monitorable = false 
	
	var tween = create_tween()
	
	# PHASE 1: THE RECOIL (Go Backwards)
	# Tween speed from 0 to -400 quickly
	tween.tween_property(self, "current_speed", recoil_speed, recoil_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# PHASE 2: THE LAUNCH (Go Forwards)
	# Tween speed from -400 to 600 
	tween.tween_property(self, "current_speed", target_speed, fly_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_body_entered(body):
	if body.is_in_group("player"):
		GameManager.gain_xp(xp_value)
		queue_free()
