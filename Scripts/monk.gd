extends CharacterBody2D

@export_group("Stats")
@export var speed = 150.0
@export var max_hp = 100.0

@export_group("Mana & Cura")
@export var max_mana = 100.0
@export var mana_regen = 10.0       # Quanto recupera por segundo
@export var mana_cost = 20.0        # Quanto gasta por segundo
@export var heal_amount = 30.0      # Cura por segundo (HPS)

var current_hp = max_hp
var current_mana = max_mana
var is_healing = false # Estado atual

# Referência ao Pet
var bear_node: CharacterBody2D = null

@onready var sprite = $AnimatedSprite2D
@onready var hp_bar = $HpBar
@onready var mana_bar = $ManaBar # A nova barra azul

func _ready():
	add_to_group("player")
	
	# Setup das Barras
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana
	mana_bar.visible = true

func _physics_process(delta):
	# 1. GERENCIAMENTO DE MANA (Passivo)
	if not is_healing and current_mana < max_mana:
		current_mana += mana_regen * delta
		current_mana = min(current_mana, max_mana)
		mana_bar.value = current_mana

	# 2. INPUT DE CURA (Canalização)
	# Se segurar o botão E tiver mana
	if Input.is_action_pressed("action") and current_mana > 0:
		start_healing(delta)
	else:
		stop_healing()
		
	# 3. MOVIMENTO (Só se não estiver curando)
	if not is_healing:
		handle_movement()
	
	move_and_slide()

func start_healing(delta):
	is_healing = true
	velocity = Vector2.ZERO
	
	if sprite.animation != "heal":
		sprite.play("heal")
	
	current_mana -= mana_cost * delta
	mana_bar.value = current_mana
	
	var heal_tick = heal_amount * delta
	heal_self(heal_tick)
	
	if is_instance_valid(bear_node):
		var dist = global_position.distance_to(bear_node.global_position)
		
		# REVIVE: Ainda exige estar perto (100px) ou você quer global também?
		# Mantive perto pois reviver à distância tira o risco do jogo.
		if bear_node.is_downed and dist < 100.0:
			bear_node.receive_revive_tick(heal_tick * 2.0)
			
		# CURA: Global (Removemos o 'dist < 250')
		elif not bear_node.is_downed:
			bear_node.receive_heal_tick(heal_tick)

func stop_healing():
	if is_healing:
		is_healing = false
		# Volta para idle se soltou o botão
		sprite.play("idle")
		
		# Avisa o urso para cortar o efeito
		if is_instance_valid(bear_node):
			bear_node.stop_heal_vfx()

func handle_movement():
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	
	if input_dir.length() > 0:
		sprite.play("run")
		if input_dir.x != 0:
			sprite.flip_h = input_dir.x < 0
	else:
		sprite.play("idle")

func heal_self(amount):
	if current_hp < max_hp:
		current_hp = min(current_hp + amount, max_hp)
		hp_bar.value = current_hp
		# Feedback visual sutil (não pisca mais loucamente)
		sprite.modulate = Color(0.8, 1.0, 0.8) # Levemente verde

func take_damage(amount):
	current_hp -= amount
	hp_bar.value = current_hp
	sprite.modulate = Color.RED
	
	# Pequeno tween para voltar a cor normal
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		print("GAME OVER")
		get_tree().reload_current_scene()
