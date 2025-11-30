extends CharacterBody2D

enum State { FOLLOW, CHASE, DOWNED }
var current_state = State.FOLLOW

@export var move_speed = 180.0
@export var max_hp = 200.0
@export var damage = 35.0

var current_hp = max_hp
var is_downed = false
var target_enemy: Node2D = null
var monk_node: Node2D = null

@onready var sprite = $Sprite2D
@onready var detection_area = $DetectionArea

func _physics_process(delta):
	if is_downed:
		# Se está caído, não faz nada. Vira uma pedra.
		velocity = Vector2.ZERO
		return

	match current_state:
		State.FOLLOW:
			behavior_follow()
		State.CHASE:
			behavior_chase()
			
	move_and_slide()

func behavior_follow():
	if not is_instance_valid(monk_node): return
	
	var dist = global_position.distance_to(monk_node.global_position)
	if dist > 80.0:
		var dir = global_position.direction_to(monk_node.global_position)
		velocity = dir * move_speed
		sprite.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		
	find_new_enemy()

func behavior_chase():
	if not is_instance_valid(target_enemy):
		current_state = State.FOLLOW
		return
		
	var dir = global_position.direction_to(target_enemy.global_position)
	velocity = dir * (move_speed * 1.2)
	sprite.flip_h = velocity.x < 0

func find_new_enemy():
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			target_enemy = body
			current_state = State.CHASE
			return

# Chamado pela AttackArea (Sinal body_entered)
func _on_attack_area_body_entered(body):
	if is_downed: return
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			# Empurrãozinho (Knockback visual opcional)

func take_damage(amount):
	if is_downed: return # Não toma dano se já estiver caído (opcional)
	
	current_hp -= amount
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	
	if not is_downed: # Checa de novo caso tenha sido curado no meio tempo
		sprite.modulate = Color.WHITE
	
	if current_hp <= 0:
		go_down()

func go_down():
	is_downed = true
	current_state = State.DOWNED
	sprite.modulate = Color(0.3, 0.3, 0.3) # Fica cinza escuro
	print("O Urso CAIU! O Monge está vulnerável!")

func revive(amount_hp):
	is_downed = false
	current_hp = amount_hp
	current_state = State.FOLLOW
	sprite.modulate = Color.WHITE
	# Efeito de "Pulo" visual
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func receive_heal(amount):
	if is_downed: return # Precisa ser revivido, não curado
	current_hp = min(current_hp + amount, max_hp)
	sprite.modulate = Color.GREEN
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color.WHITE
