extends CharacterBody2D

@export_group("Stats")
@export var speed = 150.0
@export var max_hp = 100.0
@export var heal_amount = 30.0
@export var heal_cooldown_time = 3.0

var current_hp = max_hp
var can_heal = true

# Referência ao Pet (Injetada pelo Main)
var bear_node: CharacterBody2D = null

@onready var sprite = $Sprite2D
@onready var heal_timer = $HealCooldown

func _ready():
	heal_timer.wait_time = heal_cooldown_time
	heal_timer.timeout.connect(_on_heal_timer_timeout)

func _physics_process(delta):
	# Movimento
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	
	if input_dir.x != 0:
		sprite.flip_h = input_dir.x < 0
		
	move_and_slide()
	
	# Ação de Cura / Reviver
	if Input.is_action_just_pressed("action") and can_heal:
		perform_action()

func perform_action():
	can_heal = false
	heal_timer.start()
	
	# Visual de Cooldown
	sprite.modulate = Color(0.5, 0.5, 0.5) 
	
	# 1. Cura a si mesmo
	heal_self(heal_amount)
	
	# 2. Interage com o Urso
	if is_instance_valid(bear_node):
		var dist = global_position.distance_to(bear_node.global_position)
		
		# Se o urso estiver "Caído" (Downed), revive ele
		if bear_node.is_downed:
			if dist < 100.0: # Tem que estar perto para reviver
				bear_node.revive(max_hp * 0.5) # Revive com 50% HP
				print("Urso Revivido!")
		
		# Se o urso estiver vivo e perto, cura ele
		elif dist < 250.0:
			bear_node.receive_heal(heal_amount)

func heal_self(amount):
	current_hp = min(current_hp + amount, max_hp)
	# Efeito visual (Piscada Verde)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.GREEN, 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func take_damage(amount):
	current_hp -= amount
	# Feedback de Dano (Vermelho)
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if current_hp <= 0:
		print("GAME OVER - O Monge Morreu")
		get_tree().reload_current_scene()

func _on_heal_timer_timeout():
	can_heal = true
	sprite.modulate = Color.WHITE # Volta a cor normal
	print("Cura pronta!")
