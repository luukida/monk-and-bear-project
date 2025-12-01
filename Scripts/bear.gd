extends CharacterBody2D

enum State { FOLLOW, CHASE, ATTACK, DOWNED }
var current_state = State.FOLLOW

@export_group("Stats")
@export var move_speed = 180.0
@export var max_hp = 200.0
@export var damage = 50.0

@export_group("Visual")
@export var max_rotation_degrees: float = 30.0 
@export var attack_impact_frame: int = 6

var current_hp = max_hp
var is_downed = false
var target_enemy: Node2D = null
var monk_node: Node2D = null

# Variável para memorizar a distância do SHAPE (Filho)
var default_shape_x: float = 0.0

@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea 
# PEGA O FILHO DIRETO PARA MOVER ELE
@onready var attack_shape = $AttackArea/CollisionShape2D

func _ready():
	add_to_group("bear")
	
	# Memoriza onde você colocou o colisor no editor
	default_shape_x = attack_shape.position.x
	
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	
	detection_area.monitoring = true
	detection_area.monitorable = false
	attack_area.monitoring = true
	attack_area.monitorable = false

func _physics_process(delta):
	if is_downed: return

	match current_state:
		State.FOLLOW:
			behavior_follow()
		State.CHASE:
			behavior_chase()
		State.ATTACK:
			velocity = Vector2.ZERO
			
	move_and_slide()

# --- IA ---

func behavior_follow():
	if not is_instance_valid(monk_node): return
	
	scan_for_enemies()
	if is_instance_valid(target_enemy):
		current_state = State.CHASE
		return
	
	var dist = global_position.distance_to(monk_node.global_position)
	
	if dist > 80.0:
		var dir = global_position.direction_to(monk_node.global_position)
		velocity = dir * move_speed
		sprite.play("run")
		update_orientation(monk_node.global_position)
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")
		# Reseta rotação visual quando parado
		sprite.rotation = move_toward(sprite.rotation, 0, 0.1)
		attack_area.rotation = sprite.rotation

func behavior_chase():
	if not is_instance_valid(target_enemy):
		current_state = State.FOLLOW
		return
		
	# GATILHO: Se a área encostou, bate
	if attack_area.overlaps_body(target_enemy):
		start_attack()
	else:
		var dir = global_position.direction_to(target_enemy.global_position)
		velocity = dir * (move_speed * 1.2)
		sprite.play("run")
		update_orientation(target_enemy.global_position)

func scan_for_enemies():
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			target_enemy = body
			return 

# --- ORIENTAÇÃO CORRETA (Pivô + Offset) ---

func update_orientation(target_pos: Vector2):
	var dir = global_position.direction_to(target_pos)
	
	# 1. Flip Horizontal (Mexe no SHAPE FILHO)
	if dir.x != 0:
		sprite.flip_h = dir.x < 0
		
		if dir.x < 0:
			attack_shape.position.x = -default_shape_x
		else:
			attack_shape.position.x = default_shape_x

	# 2. Rotação Vertical (Gira a AREA PAI no eixo 0,0)
	var rotation_angle = 0.0
	if dir.x < 0:
		rotation_angle = atan2(dir.y, -dir.x)
		rotation_angle = -rotation_angle 
	else:
		rotation_angle = atan2(dir.y, dir.x)
	
	var max_rad = deg_to_rad(max_rotation_degrees)
	rotation_angle = clamp(rotation_angle, -max_rad, max_rad)
	
	sprite.rotation = rotation_angle
	attack_area.rotation = rotation_angle

# --- COMBATE ---

func start_attack():
	current_state = State.ATTACK
	sprite.play("attack")
	sprite.frame = 0 
	if is_instance_valid(target_enemy):
		update_orientation(target_enemy.global_position)

func _on_frame_changed():
	if sprite.animation == "attack" and sprite.frame == attack_impact_frame:
		apply_damage_snapshot()

func apply_damage_snapshot():
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage)

func _on_animation_finished():
	if sprite.animation == "attack":
		current_state = State.CHASE

# --- VIDA ---

func take_damage(amount):
	if is_downed: return
	current_hp -= amount
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if current_hp <= 0: go_down()

func go_down():
	is_downed = true
	current_state = State.DOWNED
	sprite.modulate = Color(0.3, 0.3, 0.3)
	sprite.rotation = 0
	sprite.play("idle")
	print("Urso Caiu!")

func revive(amount_hp):
	is_downed = false
	current_hp = amount_hp
	current_state = State.FOLLOW
	sprite.modulate = Color.WHITE
	sprite.play("idle")

func receive_heal(amount):
	if is_downed: return
	current_hp = min(current_hp + amount, max_hp)
	sprite.modulate = Color.GREEN
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)
