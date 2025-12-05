extends Area2D

@export var instant_heal_amount: float = 100.0 # Valor alto pois é instantâneo

func _ready():
	# Conecta o sinal de colisão
	body_entered.connect(_on_body_entered)
	
	# Avisa o urso que tem comida no chão!
	notify_bear()

func notify_bear():
	var bears = get_tree().get_nodes_in_group("bear")
	if bears.size() > 0:
		var bear = bears[0]
		if bear.has_method("detect_honey"):
			# Manda a posição do item para o urso
			bear.detect_honey(global_position)

func _on_body_entered(body):
	var consumed = false
	
	# Se o Monge pegar
	if body.is_in_group("player") and body.has_method("heal_self"):
		body.heal_self(instant_heal_amount)
		consumed = true
		print("Monge pegou o mel!")
	
	# Se o Urso pegar
	elif body.is_in_group("bear") and body.has_method("heal_self"):
		body.heal_self(instant_heal_amount)
		
		# Avisa o urso que ele já comeu (para parar de correr atrás desse ponto)
		if body.has_method("stop_eating_honey"):
			body.stop_eating_honey()
			
		consumed = true
		print("Urso comeu o mel!")
		
	if consumed:
		# Aqui você pode tocar um som de "Glulp!"
		queue_free()
