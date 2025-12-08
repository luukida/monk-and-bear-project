extends Area2D

@export_group("Gameplay")
@export var slow_amount: float = 0.5 
@export var duration: float = 20.0

@export_group("Visuals & Animation")
@export var jump_height: float = -80.0 
@export var anim_duration: float = 0.6
@export var start_scale: float = 0.1
@export var shadow_target_scale: float = 1.0
@export var random_rotation: bool = true
# NEW: Spread Radius
@export var spread_min: float = 40.0
@export var spread_max: float = 90.0

@onready var sprite = $Sprite2D
@onready var shadow = $ShadowSprite 

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	play_spawn_animation()
	
	get_tree().create_timer(duration).timeout.connect(start_decay)

func play_spawn_animation():
	# 1. RANDOM ROTATION
	if random_rotation:
		rotation_degrees = randf_range(0.0, 360.0)
	
	# 2. SETUP
	sprite.position.y = 0.0 
	scale = Vector2(start_scale, start_scale)
	if shadow: shadow.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 3. SPREAD MOVEMENT (Fly to random spot nearby)
	# This prevents them from stacking if multiple drop at once
	var random_dir = Vector2.RIGHT.rotated(randf() * TAU)
	var random_dist = randf_range(spread_min, spread_max)
	var target_pos = global_position + (random_dir * random_dist)
	
	tween.tween_property(self, "global_position", target_pos, anim_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 4. SCALE UP
	tween.tween_property(self, "scale", Vector2.ONE, anim_duration)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# 5. VERTICAL ARC (Throw effect)
	var jump_tween = create_tween()
	var half_time = anim_duration / 2.0
	jump_tween.tween_property(sprite, "position:y", jump_height, half_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(sprite, "position:y", 0.0, half_time)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# 6. SHADOW
	if shadow:
		var shadow_tween = create_tween()
		shadow_tween.tween_property(shadow, "scale", Vector2(shadow_target_scale, shadow_target_scale), anim_duration)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func start_decay():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.finished.connect(queue_free)

func _on_body_entered(body):
	if body.has_method("apply_slow"):
		body.apply_slow(slow_amount)

func _on_body_exited(body):
	if body.has_method("remove_slow"):
		body.remove_slow()
