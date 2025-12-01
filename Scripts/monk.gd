extends CharacterBody2D

@export_group("Stats")
@export var speed = 150.0
@export var max_hp = 100.0
@export var heal_amount = 30.0
@export var heal_cooldown_time = 3.0

var current_hp = max_hp
var can_heal = true
var is_casting_heal = false # Trava de animação

# Referência ao Pet
var bear_node: CharacterBody2D = null

@onready var sprite = $AnimatedSprite2D
@onready var heal_timer = $HealCooldown

func _ready():
	add_to_group("player")
	heal_timer.wait_time = heal_cooldown_time
	heal_timer.timeout.connect(_on_heal_timer_timeout)
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# Se estiver no meio da animação de cura, não anda
	if is_casting_heal:
		return

	# Movimento
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	
	# Controle de Animação de Movimento
	if input_dir.length() > 0:
		sprite.play("run")
		if input_dir.x != 0:
			sprite.flip_h = input_dir.x < 0
	else:
		sprite.play("idle")
		
	move_and_slide()
	
	# Input de Ação
	if Input.is_action_just_pressed("action") and can_heal:
		perform_heal_action()

func perform_heal_action():
	can_heal = false
	is_casting_heal = true # Trava o movimento
	velocity = Vector2.ZERO
	
	sprite.play("heal") # Toca animação
	heal_timer.start()
	
	# Lógica Matemática da Cura
	heal_self(heal_amount)
	
	if is_instance_valid(bear_node):
		var dist = global_position.distance_to(bear_node.global_position)
		if bear_node.is_downed and dist < 100.0:
			bear_node.revive(max_hp * 0.5)
		elif dist < 250.0:
			bear_node.receive_heal(heal_amount)

func _on_animation_finished():
	if sprite.animation == "heal":
		is_casting_heal = false # Libera o movimento

func heal_self(amount):
	current_hp = min(current_hp + amount, max_hp)
	sprite.modulate = Color.GREEN
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func take_damage(amount):
	current_hp -= amount
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		print("GAME OVER")
		get_tree().reload_current_scene()

func _on_heal_timer_timeout():
	can_heal = true
	# Feedback visual sutil que a cura voltou
	sprite.modulate = Color(0.7, 0.7, 1.0) 
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
