extends CharacterBody2D

enum State { CHASE, PREPARE, ATTACK }
var current_state = State.CHASE

@export_group("Stats")
@export var hp = 30.0
@export var speed = 80.0
@export var damage = 10.0
@export var contact_damage = 10.0

@export_group("Combate")
@export var attack_speed: float = 1.0 # 1.0 = Normal, 2.0 = 2x Faster
@export var base_telegraph_duration: float = 0.6 # The standard "wind up" time for this enemy type
@export var max_rotation_degrees: float = 40.0
@export var attack_impact_frame: int = 1 

# Referências Globais
var player_ref: Node2D = null
var bear_ref: CharacterBody2D = null
var target: Node2D = null

# Variáveis Internas
var default_shape_x: float = 0.0
var default_telegraph_x: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO

# Nós Filhos
@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $EnemyHitbox
@onready var hitbox_shape = $EnemyHitbox/CollisionShape2D
@onready var telegraph = $EnemyHitbox/TelegraphSprite 
@onready var contact_area = $ContactArea

var gem_scene = preload("res://Scenes/experience_gem.tscn")

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
	
	contact_area.monitoring = true
	contact_area.monitorable = false
	
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
			velocity = Vector2.ZERO
		State.ATTACK:
			velocity = Vector2.ZERO
			
	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
			
	move_and_slide()
	apply_contact_damage(delta)

# --- IA E MOVIMENTO ---

func select_target() -> Node2D:
	if is_instance_valid(bear_ref) and bear_ref.get("is_downed"):
		return player_ref
		
	if not is_instance_valid(player_ref): return null
	if not is_instance_valid(bear_ref): return player_ref

	var dist_player = global_position.distance_squared_to(player_ref.global_position)
	var dist_bear = global_position.distance_squared_to(bear_ref.global_position)
	
	return bear_ref if dist_bear < dist_player else player_ref

func behavior_chase():
	# Ensure speed scale is normal when running (Thief overrides this, which is fine)
	sprite.speed_scale = 1.0 
	
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

# --- SISTEMA DE TELEGRAPH (UPDATED) ---

func start_telegraph():
	current_state = State.PREPARE
	sprite.play("idle")
	
	if is_instance_valid(target):
		update_orientation(target.global_position)
	
	# FORMULA: Duration gets shorter as Attack Speed increases
	var actual_duration = base_telegraph_duration / attack_speed
	
	if telegraph:
		telegraph.visible = true
		var tween = create_tween()
		telegraph.modulate.a = 0.0
		tween.tween_property(telegraph, "modulate:a", 0.8, actual_duration)
	
	await get_tree().create_timer(actual_duration).timeout
	
	if current_state == State.PREPARE:
		start_attack()

# --- COMBATE (UPDATED) ---

func start_attack():
	current_state = State.ATTACK
	if telegraph: telegraph.visible = false
	
	sprite.play("attack")
	sprite.frame = 0
	
	# FORMULA: Animation plays faster if Attack Speed is higher
	sprite.speed_scale = attack_speed 

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
		sprite.speed_scale = 1.0 # Reset speed for running

# --- DANO DE CONTATO ---

func apply_contact_damage(_delta):
	var bodies = contact_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(contact_damage)

# --- VIDA E FÍSICA ---

func apply_knockback(force_vector: Vector2):
	knockback_velocity = force_vector
	
	if current_state == State.PREPARE or current_state == State.ATTACK:
		current_state = State.CHASE
		if telegraph: telegraph.visible = false
		sprite.speed_scale = 1.0

func take_damage(amount):
	hp -= amount
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		spawn_gem()
		queue_free()

func spawn_gem():
	if gem_scene:
		var gem = gem_scene.instantiate()
		gem.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", gem)
