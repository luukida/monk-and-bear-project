extends Line2D

@export_group("Referências")
@export var player: CharacterBody2D
@export var bear: CharacterBody2D

@export_group("Física da Corda")
@export var max_length: float = 250.0 
@export var pull_strength: float = 20.0  
@export var max_durability: float = 100.0
@export var durability_regen: float = 20.0
@export var durability_loss: float = 40.0 # Aumentei um pouco para punir a resistência

@export_group("Visual")
@export var base_width: float = 10.0 

var current_durability = max_durability
var is_broken = false
var repair_progress = 0.0

func _ready():
	#z_index = 5 
	width = base_width

func _physics_process(delta):
	if not is_instance_valid(player) or not is_instance_valid(bear):
		clear_points()
		return

	if is_broken:
		handle_broken_state(delta)
		return

	# Visual
	clear_points()
	add_point(to_local(player.global_position))
	add_point(to_local(bear.global_position))

	# Lógica de Tensão
	var distance = player.global_position.distance_to(bear.global_position)
	
	if distance > max_length:
		apply_smart_tension(distance, delta)
	else:
		recover_durability(delta)
		
	update_rope_color()

func apply_smart_tension(distance, delta):
	var direction_to_bear = player.global_position.direction_to(bear.global_position)
	var overstretch = distance - max_length
	
	# 1. CÁLCULO DA FORÇA
	# Força elástica baseada na distância
	var force_magnitude = overstretch * pull_strength
	
	# GARANTIA DE ARRASTO:
	# Se a força ficar muito pequena (finalzinho do puxão), forçamos um mínimo
	# para vencer o atrito do jogador e garantir que ele entre na zona segura.
	if force_magnitude < 100.0: 
		force_magnitude = 100.0
		
	var final_force = direction_to_bear * force_magnitude
	
	# Aplica no Player
	if player.has_method("apply_rope_pull"):
		player.apply_rope_pull(final_force)
	
	# 2. VERIFICA RESISTÊNCIA (DURABILIDADE)
	var is_resisting = false
	
	if player.has_method("get_movement_input"):
		var input = player.get_movement_input()
		
		# Produto Escalar (Dot Product):
		# Se for < -0.5, significa que o input é OPOSTO à direção do urso.
		# O jogador está puxando contra a corda.
		if input.dot(direction_to_bear) < -0.5:
			is_resisting = true
			
	# 3. APLICA DANO OU CURA NA CORDA
	if is_resisting:
		# Jogador lutando contra -> Corda sofre
		current_durability -= durability_loss * delta
		if current_durability <= 0:
			break_rope()
	else:
		# Jogador aceitou ser arrastado -> Corda alivia
		recover_durability(delta)

func recover_durability(delta):
	if current_durability < max_durability:
		current_durability += durability_regen * delta
		current_durability = min(current_durability, max_durability)

func update_rope_color():
	var ratio = current_durability / max_durability
	default_color = Color(1.0, ratio, ratio) 
	# Efeito visual: Corda fica fina quando está prestes a estourar
	width = base_width * (0.3 + (ratio * 0.7)) 

func break_rope():
	is_broken = true
	print("CORDA QUEBROU!")
	clear_points()
	if bear.has_method("enter_frenzy"):
		bear.enter_frenzy()

func handle_broken_state(delta):
	if not bear.is_downed:
		bear.enter_frenzy()

	var dist = player.global_position.distance_to(bear.global_position)
	
	# Mecânica de Reparo (Segurar botão perto)
	if dist < 150.0 and Input.is_action_pressed("action") and not bear.is_downed:
		repair_progress += delta
		
		# Feedback visual piscante
		if int(repair_progress * 10) % 2 == 0:
			default_color = Color.CYAN
			width = base_width 
			clear_points()
			add_point(to_local(player.global_position))
			add_point(to_local(bear.global_position))
		else:
			clear_points()
			
		if repair_progress >= 3.0:
			fix_rope()
	else:
		repair_progress = 0.0
		clear_points()

func fix_rope():
	is_broken = false
	current_durability = max_durability
	repair_progress = 0.0
	print("Corda consertada!")
	if bear.has_method("exit_frenzy"):
		bear.exit_frenzy()
