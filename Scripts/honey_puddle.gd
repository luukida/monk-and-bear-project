extends Area2D

@export var heal_amount = 15.0 
@export var duration = 5.0 

func _ready():
	get_tree().create_timer(duration).timeout.connect(queue_free)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(duration - 0.5)
	
	var bears = get_tree().get_nodes_in_group("bear")
	if bears.size() > 0:
		var bear = bears[0]
		if bear.has_method("detect_honey"):
			# Passa a posição e a duração da poça
			bear.detect_honey(global_position, duration)

func _physics_process(delta):
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.has_method("receive_heal_tick"):
			body.receive_heal_tick(heal_amount * delta)
