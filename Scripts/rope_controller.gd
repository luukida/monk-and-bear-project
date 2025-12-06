extends Line2D

@export_group("Referências")
@export var player: CharacterBody2D
@export var bear: CharacterBody2D

@export_group("Física da Corda")
@export var max_length: float = 250.0 
@export var pull_strength: float = 20.0  
@export var max_durability: float = 100.0
@export var durability_regen: float = 10.0
@export var durability_loss: float = 40.0

@export_group("Visual")
@export var base_width: float = 10.0 
# Lifts the rope attachment point (Negative Y goes UP)
@export var rope_attach_offset: Vector2 = Vector2(0, -30) 

@export_group("Shadow Settings")
@export var shadow_offset: Vector2 = Vector2(0, 10) 
# Updated Default: Alpha 0.6 (60%)
@export var shadow_color: Color = Color(0, 0, 0, 0.6) 
# Updated Default: 0.04
@export var shadow_width_multiplier: float = 0.04 

var current_durability = max_durability
var is_broken = false
var repair_progress = 0.0

# SHADOW NODE
var shadow_line: Line2D

# REFERÊNCIAS
@onready var rope_hurtbox = $RopeHurtbox
@onready var rope_shape = $RopeHurtbox/CollisionShape2D

func _ready():
	width = base_width
	
	if rope_hurtbox:
		rope_hurtbox.add_to_group("rope")
	
	# --- CREATE SHADOW PROGRAMMATICALLY ---
	shadow_line = Line2D.new()
	shadow_line.name = "RopeShadow"
	shadow_line.show_behind_parent = true 
	shadow_line.default_color = shadow_color
	shadow_line.texture = null 
	
	shadow_line.width = width * shadow_width_multiplier
	
	# Updated: Removed Round Caps
	shadow_line.begin_cap_mode = Line2D.LINE_CAP_NONE
	shadow_line.end_cap_mode = Line2D.LINE_CAP_NONE
	
	add_child(shadow_line)
	shadow_line.position = shadow_offset

func _physics_process(delta):
	if not is_instance_valid(player) or not is_instance_valid(bear):
		clear_points()
		shadow_line.clear_points()
		return

	if is_broken:
		handle_broken_state(delta)
		if rope_shape: rope_shape.disabled = true
		update_shadow()
		return
	else:
		if rope_shape: rope_shape.disabled = false

	# --- CÁLCULO DE POSIÇÃO (COM OFFSET DE ALTURA) ---
	# Adds the offset to lift the rope from the feet
	var point_a = to_local(player.global_position + rope_attach_offset)
	var point_b = to_local(bear.global_position + rope_attach_offset)
	
	# --- VISUAL (Line2D) ---
	clear_points()
	add_point(point_a)
	add_point(point_b)
	
	update_shadow()
	
	# --- FÍSICA (SegmentShape2D) ---
	# Moves the hitbox up with the rope
	if rope_shape and rope_shape.shape is SegmentShape2D:
		rope_shape.shape.a = point_a
		rope_shape.shape.b = point_b

	# --- TENSÃO E REGENERAÇÃO ---
	var distance = player.global_position.distance_to(bear.global_position)
	
	if distance > max_length:
		apply_smart_tension(distance, delta)
	else:
		recover_durability(delta)
		
	update_rope_color()

func update_shadow():
	shadow_line.points = points
	shadow_line.width = width * shadow_width_multiplier

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
func take_damage(amount):
	if is_broken: return
	
	current_durability -= amount
	default_color = Color(0.5, 0, 0) 
	
	if current_durability <= 0:
		break_rope()

func break_rope():
	is_broken = true
	print("CORDA CORTADA!")
	clear_points()
	shadow_line.clear_points() 
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
			# Apply offset here too so the repair blinking looks correct
			add_point(to_local(player.global_position + rope_attach_offset))
			add_point(to_local(bear.global_position + rope_attach_offset))
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
