extends Node2D

@onready var sprite = $Sprite2D

func _ready():
	# Simple pulsing animation to warn the player/enemies
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", Vector2(1.02, 1.02), 0.3)
	tween.tween_property(sprite, "scale", Vector2(0.98, 0.98), 0.3)
