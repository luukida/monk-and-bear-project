extends Area2D

@export var total_heal: float = 100.0 
@export var heal_duration: float = 5.0 # Heals over 5 seconds

func _ready():
	body_entered.connect(_on_body_entered)
	notify_bear()

func notify_bear():
	var bears = get_tree().get_nodes_in_group("bear")
	if bears.size() > 0:
		var bear = bears[0]
		if bear.has_method("detect_honey"):
			bear.detect_honey(global_position)

func _on_body_entered(body):
	var consumed = false
	
	# Check if body can receive Heal Over Time
	if body.has_method("start_heal_over_time"):
		if body.is_in_group("player"):
			body.start_heal_over_time(total_heal, heal_duration)
			consumed = true
			print("Monk started healing over time!")
			
		elif body.is_in_group("bear"):
			body.start_heal_over_time(total_heal, heal_duration)
			
			# Stop chasing this specific pot
			if body.has_method("stop_eating_honey"):
				body.stop_eating_honey()
				
			consumed = true
			print("Bear started healing over time!")
	
	if consumed:
		queue_free()
