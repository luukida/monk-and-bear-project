extends CharacterBody2D

enum State { CHASE, PREPARE, ATTACK }
var current_state = State.CHASE

@export_group("Stats")
@export var speed = 80.0
@export var hp = 30.0
@export var damage = 10.0

@export_group("Combate")
@export var max_rotation_degrees: float = 30.0
@export var attack_impact_frame: int = 1 
@export var telegraph_duration: float = 0.6 

# Referências
var player_ref: Node2D = null
var bear_ref: CharacterBody2D = null
var target: Node2D = null

var default_shape_x: float = 0.0
var default_telegraph_x: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $EnemyHitbox
@onready var hitbox_shape = $EnemyHitbox/CollisionShape2D
@onready var telegraph = $EnemyHitbox/TelegraphSprite 

func _ready():
	add_to_group("enemy")
	
	default_shape_x = hitbox_shape.position.x
	
	if telegraph:
		default_telegraph_x = telegraph.position.x
		telegraph.visible = false
	
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	
	hitbox.monitoring = true
	hitbox.monitorable = false
	
	player_ref = get_tree().get_first_node_in_group("player")
	var bears = get_tree().get_nodes_in_group("bear")
	if bears.size() > 0:
		bear_ref = bears[0]

func _physics_process(delta):
	target = select_target()
	
	match current_state:
		State.CHASE:
			behavior_chase()
		State.PREPARE:
			velocity = Vector2.ZERO # Parado e TRAVADO (Não gira)
		State.ATTACK:
			velocity = Vector2.ZERO # Parado batendo
			
	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
			
	move_and_slide()

func select_target() -> Node2D:
	if is_instance_valid(bear_ref) and bear_ref.get("is_downed"):
		return player_ref
	if not is_instance_valid(player_ref): return null
	if not is_instance_valid(bear_ref): return player_ref

	var dist_player = global_position.distance_squared_to(player_ref.global_position)
	var dist_bear = global_position.distance_squared_to(bear_ref.global_position)
	
	return bear_ref if dist_bear < dist_player else player_ref

func behavior_chase():
	if not is_instance_valid(target):
		sprite.play("idle")
		velocity = Vector2.ZERO
		return
	
	if knockback_velocity.length() > 50:
		sprite.play("idle")
		return

	if hitbox.overlaps_body(target):
		start_telegraph()
	else:
		var dir = global_position.direction_to(target.global_position)
		velocity = dir * speed
		sprite.play("run")
		update_orientation(target.global_position)

func update_orientation(target_pos: Vector2):
	var dir = global_position.direction_to(target_pos)
	
	if dir.x != 0:
		sprite.flip_h = dir.x < 0
		
		if dir.x < 0:
			hitbox_shape.position.x = -default_shape_x
			if telegraph: telegraph.position.x = -default_telegraph_x
		else:
			hitbox_shape.position.x = default_shape_x
			if telegraph: telegraph.position.x = default_telegraph_x

	var rotation_angle = 0.0
	if dir.x < 0:
		rotation_angle = atan2(dir.y, -dir.x)
		rotation_angle = -rotation_angle
	else:
		rotation_angle = atan2(dir.y, dir.x)
	
	var max_rad = deg_to_rad(max_rotation_degrees)
	rotation_angle = clamp(rotation_angle, -max_rad, max_rad)
	
	sprite.rotation = rotation_angle
	hitbox.rotation = rotation_angle

# --- SISTEMA DE TELEGRAPH (Correção de Mira) ---

func start_telegraph():
	current_state = State.PREPARE
	sprite.play("idle")
	
	# A CORREÇÃO:
	# Miramos no alvo AGORA (no início do preparo) e nunca mais mexemos.
	if is_instance_valid(target):
		update_orientation(target.global_position)
	
	if telegraph:
		telegraph.visible = true
		var tween = create_tween()
		telegraph.modulate.a = 0.0
		tween.tween_property(telegraph, "modulate:a", 0.8, telegraph_duration)
	
	await get_tree().create_timer(telegraph_duration).timeout
	
	if current_state == State.PREPARE:
		start_attack()

# --- COMBATE ---

func start_attack():
	current_state = State.ATTACK
	
	if telegraph: telegraph.visible = false
	
	sprite.play("attack")
	sprite.frame = 0
	
	# REMOVIDO: update_orientation(target)
	# Não atualizamos a mira aqui! Ele bate onde estava mirando antes.

func _on_frame_changed():
	if sprite.animation == "attack" and sprite.frame == attack_impact_frame:
		apply_damage_snapshot()

func apply_damage_snapshot():
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			if not body.is_in_group("enemy"):
				body.take_damage(damage)

func _on_animation_finished():
	if sprite.animation == "attack":
		current_state = State.CHASE

# --- VIDA/KNOCKBACK ---

func take_damage(amount):
	hp -= amount
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		queue_free()

func apply_knockback(force_vector: Vector2):
	knockback_velocity = force_vector
	if current_state == State.PREPARE or current_state == State.ATTACK:
		current_state = State.CHASE
		if telegraph: telegraph.visible = false
