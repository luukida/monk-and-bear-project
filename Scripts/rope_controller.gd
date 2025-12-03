extends Line2D

@export_group("Referências")
@export var player: CharacterBody2D
@export var bear: CharacterBody2D

@export_group("Física da Corda")
@export var max_length: float = 250.0 
@export var pull_strength: float = 20.0  
@export var max_durability: float = 100.0
@export var durability_regen: float = 20.0
@export var durability_loss: float = 40.0

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

	# --- LÓGICA DE QUEBRA DESATIVADA ---
	# if is_broken:
	#     handle_broken_state(delta)
	#     return

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
		
	# A cor ainda pode mudar para indicar tensão, mas não quebra
	update_rope_color()

func apply_smart_tension(distance, delta):
	var direction_to_bear = player.global_position.direction_to(bear.global_position)
	var overstretch = distance - max_length
	
	# FORÇA BRUTA (Mantida para arrastar o player)
	var force_magnitude = overstretch * pull_strength
	if force_magnitude < 100.0: 
		force_magnitude = 100.0
		
	var final_force = direction_to_bear * force_magnitude
	
	if player.has_method("apply_rope_pull"):
		player.apply_rope_pull(final_force)
	
	# --- DANO NA CORDA DESATIVADO ---
	# var is_resisting = false
	# if player.has_method("get_movement_input"):
	#     var input = player.get_movement_input()
	#     if input.dot(direction_to_bear) < -0.5:
	#         is_resisting = true
			
	# if is_resisting:
	#     current_durability -= durability_loss * delta
	#     if current_durability <= 0:
	#         break_rope()
	# else:
	#     recover_durability(delta)

func recover_durability(delta):
	if current_durability < max_durability:
		current_durability += durability_regen * delta
		current_durability = min(current_durability, max_durability)

func update_rope_color():
	# Mantemos o feedback visual: Se o jogador resistir muito, a corda fica vermelha
	# Mas ela nunca "estoura". Apenas avisa "Ei, vem logo!".
	var ratio = current_durability / max_durability
	default_color = Color(1.0, ratio, ratio) 
	width = base_width * (0.3 + (ratio * 0.7)) 

# func break_rope(): ... (Ignorado)
# func handle_broken_state(delta): ... (Ignorado)
# func fix_rope(): ... (Ignorado)
