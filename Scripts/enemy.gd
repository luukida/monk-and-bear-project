extends CharacterBody2D

enum EnemyType { GRUNT, STALKER, BRUTE }
@export var enemy_type = EnemyType.GRUNT

@export var speed = 100.0
@export var hp = 30.0
@export var damage = 10.0

# Referências globais (buscadas no ready)
var player_ref: Node2D = null
var bear_ref: Node2D = null

func _ready():
	add_to_group("enemy")
	# Busca referências únicas na árvore
	player_ref = get_tree().get_first_node_in_group("player")
	# O urso pode não estar no grupo "bear" se você esqueceu, 
	# mas vamos assumir que o Main vai passar ou buscaremos pelo grupo
	var bears = get_tree().get_nodes_in_group("bear")
	if bears.size() > 0:
		bear_ref = bears[0]

func _physics_process(delta):
	var target = select_target()
	
	if is_instance_valid(target):
		var dir = global_position.direction_to(target.global_position)
		velocity = dir * speed
		move_and_slide()
		
		# Colisão para causar dano
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# Só dá dano se o alvo estiver vivo (Bear Downed não toma dano físico aqui)
			if collider.has_method("take_damage"):
				# Verifica se o urso está caído
				if collider.name == "Bear" and collider.is_downed:
					continue # Ignora colisão com urso caído
				
				collider.take_damage(damage * delta)

func select_target() -> Node2D:
	# Se o Urso caiu, TODOS atacam o Monge (Pânico!)
	if is_instance_valid(bear_ref) and bear_ref.is_downed:
		return player_ref

	match enemy_type:
		EnemyType.STALKER:
			return player_ref # Foca no Monge
		EnemyType.BRUTE:
			return bear_ref # Foca no Tanque
		EnemyType.GRUNT:
			# Ataca quem estiver mais perto
			if not is_instance_valid(bear_ref): return player_ref
			if not is_instance_valid(player_ref): return null
			
			var dist_player = global_position.distance_squared_to(player_ref.global_position)
			var dist_bear = global_position.distance_squared_to(bear_ref.global_position)
			
			return bear_ref if dist_bear < dist_player else player_ref
			
	return player_ref

func take_damage(amount):
	hp -= amount
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		queue_free()
