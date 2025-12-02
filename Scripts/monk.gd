extends CharacterBody2D

@export_group("Stats")
@export var speed = 150.0
@export var max_hp = 100.0
@export var invulnerability_duration: float = 1.0

@export_group("Mana & Cura")
@export var max_mana = 100.0
@export var mana_regen = 10.0       
@export var mana_cost = 20.0        
@export var heal_amount = 30.0      

var current_hp = max_hp
var current_mana = max_mana
var is_healing = false 
var is_invincible = false

# VARIÁVEL NOVA: Força externa (Corda/Empurrão)
var external_velocity: Vector2 = Vector2.ZERO

var bear_node: CharacterBody2D = null

@onready var sprite = $AnimatedSprite2D
@onready var hp_bar = $HpBar     
@onready var mana_bar = $ManaBar 

func _ready():
	add_to_group("player")
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana
	mana_bar.visible = true

func _physics_process(delta):
	if not is_healing and current_mana < max_mana:
		current_mana += mana_regen * delta
		mana_bar.value = current_mana

	if Input.is_action_pressed("action") and current_mana > 0:
		start_healing(delta)
	else:
		stop_healing()
		
	if not is_healing:
		handle_movement(delta) # Passamos delta agora
	else:
		# Se estiver curando, aplica atrito na força externa também
		external_velocity = external_velocity.move_toward(Vector2.ZERO, 500 * delta)
		velocity = external_velocity # Mantém o deslize se houver
	
	move_and_slide()

func apply_rope_pull(pull_vector: Vector2):
	# Esta função é chamada pelo RopeController
	external_velocity = pull_vector

func handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Movimento do Jogador
	var player_velocity = input_dir * speed
	
	# SOMA DE FORÇAS: Input + Corda
	velocity = player_velocity + external_velocity
	
	# Amortecimento da força externa (para não deslizar pra sempre se a corda soltar)
	external_velocity = external_velocity.move_toward(Vector2.ZERO, 300 * delta)
	
	if input_dir.length() > 0:
		sprite.play("run")
		if input_dir.x != 0:
			sprite.flip_h = input_dir.x < 0
	else:
		sprite.play("idle")

# ... (Mantenha start_healing, stop_healing, take_damage, heal_self iguais ao anterior) ...
# Copie do script anterior se precisar, apenas a lógica de movimento mudou.
func start_healing(delta):
	is_healing = true
	if sprite.animation != "heal": sprite.play("heal")
	current_mana -= mana_cost * delta
	mana_bar.value = current_mana
	var heal_tick = heal_amount * delta
	heal_self(heal_tick)
	if is_instance_valid(bear_node):
		if not bear_node.is_downed: bear_node.receive_heal_tick(heal_tick)
		else: bear_node.stop_heal_vfx()

func stop_healing():
	if is_healing:
		is_healing = false
		sprite.play("idle")
		if is_instance_valid(bear_node): bear_node.stop_heal_vfx()

func heal_self(amount):
	if current_hp < max_hp:
		current_hp = min(current_hp + amount, max_hp)
		hp_bar.value = current_hp
		sprite.modulate = Color(0.8, 1.0, 0.8) 
	else: sprite.modulate = Color.WHITE

func take_damage(amount):
	if is_invincible: return
	current_hp -= amount
	hp_bar.value = current_hp
	if current_hp <= 0:
		print("GAME OVER")
		get_tree().reload_current_scene()
		return
	is_invincible = true
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	for i in range(5):
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.5), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.finished.connect(func(): is_invincible = false)

# Função auxiliar para a corda saber a intenção do jogador
func get_movement_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
