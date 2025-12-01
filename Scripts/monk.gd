extends CharacterBody2D

@export_group("Stats")
@export var speed = 150.0
@export var max_hp = 100.0
@export var heal_amount = 30.0
@export var heal_cooldown_time = 3.0

var current_hp = max_hp
var can_heal = true
var is_casting_heal = false 

var bear_node: CharacterBody2D = null

@onready var sprite = $AnimatedSprite2D
@onready var heal_timer = $HealCooldown
# REFERÊNCIA NOVA: A Barra de Vida
@onready var hp_bar = $ProgressBar

func _ready():
	add_to_group("player")
	
	# CONFIGURAÇÃO INICIAL DA BARRA
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.visible = true # Garante que está visível
	
	heal_timer.wait_time = heal_cooldown_time
	if not heal_timer.timeout.is_connected(_on_heal_timer_timeout):
		heal_timer.timeout.connect(_on_heal_timer_timeout)
	
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if is_casting_heal: return

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	
	if input_dir.length() > 0:
		sprite.play("run")
		if input_dir.x != 0:
			sprite.flip_h = input_dir.x < 0
	else:
		sprite.play("idle")
		
	move_and_slide()
	
	if Input.is_action_just_pressed("action") and can_heal:
		perform_heal_action()

func perform_heal_action():
	can_heal = false
	is_casting_heal = true 
	velocity = Vector2.ZERO
	
	sprite.play("heal")
	heal_timer.start()
	
	heal_self(heal_amount)
	
	if is_instance_valid(bear_node):
		var dist = global_position.distance_to(bear_node.global_position)
		
		if bear_node.is_downed and dist < 100.0:
			# Revive com vida cheia (Opção A que discutimos)
			bear_node.revive(bear_node.max_hp)
			print("Monge reviveu o Urso!")
			
		elif not bear_node.is_downed and dist < 250.0:
			bear_node.receive_heal(heal_amount)

func _on_animation_finished():
	if sprite.animation == "heal":
		is_casting_heal = false

func heal_self(amount):
	current_hp = min(current_hp + amount, max_hp)
	# ATUALIZA A BARRA
	hp_bar.value = current_hp
	
	sprite.modulate = Color.GREEN
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func take_damage(amount):
	current_hp -= amount
	# ATUALIZA A BARRA
	hp_bar.value = current_hp
	
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		print("GAME OVER")
		get_tree().reload_current_scene()

func _on_heal_timer_timeout():
	can_heal = true
	sprite.modulate = Color(0.7, 0.7, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
