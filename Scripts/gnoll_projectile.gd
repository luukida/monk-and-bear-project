extends Area2D

@export var speed = 200.0 # Atualizado para 200
@export var damage = 25.0 # Atualizado para 25
var direction = Vector2.ZERO

func _ready():
	# Segurança: Se esqueceu de conectar no editor, conecta aqui via código
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Destrói depois de 5 segundos para não lagar o jogo se errar tudo
	await get_tree().create_timer(5.0).timeout
	queue_free()

func launch(start_pos, target_pos):
	global_position = start_pos
	direction = (target_pos - start_pos).normalized()
	rotation = direction.angle()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	# DEBUG: Se aparecer isso no output, a colisão física funcionou
	# print("Projétil bateu em: ", body.name)
	
	if body.has_method("take_damage"):
		# Verifica se é Player ou Urso
		if body.is_in_group("player") or body.is_in_group("bear"):
			body.take_damage(damage)
			queue_free()
		
		# Se bater em parede (World), também some
		# (Assumindo que Paredes não estão no grupo enemy)
		elif not body.is_in_group("enemy"): 
			queue_free()
