extends Node2D

func _ready():
	# Simple bobbing animation
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -10.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)

func kill():
	queue_free()
