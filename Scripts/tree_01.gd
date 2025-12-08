extends StaticBody2D

func _ready():
	# Randomize frame so trees don't sway in perfect sync
	var anim = $AnimatedSprite2D
	anim.frame = randi() % anim.sprite_frames.get_frame_count(anim.animation)

	# Jitter position slightly (e.g., +/- 16 pixels) to break the grid
	position += Vector2(randf_range(-16, 16), randf_range(-16, 16))
