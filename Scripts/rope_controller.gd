extends Line2D

@export_group("Referências")
@export var player: CharacterBody2D
@export var bear: CharacterBody2D

@export_group("Física da Corda")
@export var max_length: float = 250.0 
@export var pull_strength: float = 20.0  
@export var max_durability: float = 100.0
@export var durability_regen: float = 10.0 # Reduzi um pouco regen
@export var durability_loss: float = 40.0

@export_group("Visual")
@export var base_width: float = 10.0 

var current_durability = max_durability
var is_broken = false
var repair_progress = 0.0

# REFERÊNCIA AO SHAPE FÍSICO
@onready var rope_hurtbox = $RopeHurtbox
@onready var rope_shape = $RopeHurtbox/CollisionShape2D

func _ready():
	#z_index = 5 
	width = base_width
	
	# Garante que está no grupo para os inimigos acharem
	if rope_hurtbox:
		rope_hurtbox.add_to_group("rope")

func _physics_process(delta):
	if not is_instance_valid(player) or not is_instance_valid(bear):
		clear_points()
		return

	if is_broken:
		handle_broken_state(delta)
		# Se quebrou, desativa o colisor para não apanhar mais
		if rope_shape: rope_shape.disabled = true
		return
	else:
		if rope_shape: rope_shape.disabled = false

	# --- CÁLCULO DE POSIÇÃO ---
	var point_a = to_local(player.global_position)
	var point_b = to_local(bear.global_position)
	
	# --- VISUAL (Line2D) ---
	clear_points()
	add_point(point_a)
	add_point(point_b)
	
	# --- FÍSICA (SegmentShape2D) ---
	# Atualiza o colisor para bater com o visual
	if rope_shape and rope_shape.shape is SegmentShape2D:
		rope_shape.shape.a = point_a
		rope_shape.shape.b = point_b

	# --- TENSÃO E REGENERAÇÃO ---
	var distance = player.global_position.distance_to(bear.global_position)
	
	if distance > max_length:
		apply_smart_tension(distance, delta)
	else:
		# Só regenera se não estiver tomando dano (opcional)
		recover_durability(delta)
		
	update_rope_color()

func apply_smart_tension(distance, delta):
	var direction_to_bear = player.global_position.direction_to(bear.global_position)
	var overstretch = distance - max_length
	
	var force_magnitude = overstretch * pull_strength
	if force_magnitude < 100.0: force_magnitude = 100.0
	var final_force = direction_to_bear * force_magnitude
	
	if player.has_method("apply_rope_pull"):
		player.apply_rope_pull(final_force)

func recover_durability(delta):
	if current_durability < max_durability:
		current_durability += durability_regen * delta
		current_durability = min(current_durability, max_durability)

func update_rope_color():
	var ratio = current_durability / max_durability
	default_color = Color(1.0, ratio, ratio) 
	width = base_width * (0.3 + (ratio * 0.7)) 

# --- SISTEMA DE DANO NA CORDA ---
# Esta função será chamada pelo Inimigo Cortador
func take_damage(amount):
	if is_broken: return
	
	current_durability -= amount
	# Feedback visual instantâneo (pisca vermelho escuro)
	default_color = Color(0.5, 0, 0) 
	
	if current_durability <= 0:
		break_rope()

func break_rope():
	is_broken = true
	print("CORDA CORTADA!")
	clear_points()
	if bear.has_method("enter_frenzy"):
		bear.enter_frenzy()

func handle_broken_state(delta):
	if not bear.is_downed:
		bear.enter_frenzy()

	var dist = player.global_position.distance_to(bear.global_position)
	
	if dist < 150.0 and Input.is_action_pressed("action") and not bear.is_downed:
		repair_progress += delta
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
