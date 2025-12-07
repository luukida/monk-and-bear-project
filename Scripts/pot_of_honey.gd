extends Area2D

# --- HEAL OVER TIME VARIABLES ---
@export var total_heal: float = 100.0 
@export var heal_duration: float = 5.0 

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
	
	# Scenario 1: Monk picks it up
	if body.is_in_group("player"):
		# Try to call HoT function first
		if body.has_method("start_heal_over_time"):
			body.start_heal_over_time(total_heal, heal_duration)
			consumed = true
		elif body.has_method("heal_self"):
			body.heal_self(total_heal)
			consumed = true
			
		if consumed:
			print("Monk stole the honey!")
			# FIX: Tell Bear to stop chasing immediately!
			var bears = get_tree().get_nodes_in_group("bear")
			if bears.size() > 0:
				var bear = bears[0]
				if bear.has_method("stop_eating_honey"):
					bear.stop_eating_honey()
	
	# Scenario 2: Bear eats it
	elif body.is_in_group("bear"):
		if body.has_method("start_heal_over_time"):
			body.start_heal_over_time(total_heal, heal_duration)
			consumed = true
		elif body.has_method("heal_self"):
			body.heal_self(total_heal)
			consumed = true
		
		if consumed:
			if body.has_method("stop_eating_honey"):
				body.stop_eating_honey()
			print("Bear ate the honey!")
		
	if consumed:
		queue_free()
