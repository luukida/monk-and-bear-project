extends CharacterBody2D

@export_group("Stats")
@export var speed = 150.0
@export var max_hp = 100.0
@export var invulnerability_duration: float = 1.0

# --- CONFIGURAÇÃO DA SKILL 1 (MEL) ---
@export_group("Skill 1: Mel Sagrado")
@export var honey_cooldown_time = 5.0
@export var honey_throw_range = 300.0

@export_group("Visual")
@export var heal_animation_name: String = "healVFX" 

var honey_current_cooldown = 0.0
var honey_projectile_scene = preload("res://Scenes/honey_pot_projectile.tscn")

# ESTADOS
var current_hp = max_hp
var is_invincible = false
var is_aiming_skill_1 = false 
var is_healing = false # Controle interno de cura

# FÍSICA
var external_velocity: Vector2 = Vector2.ZERO
var bear_node: CharacterBody2D = null

# REFERÊNCIAS
@onready var sprite = $AnimatedSprite2D
@onready var hp_bar = $HpBar     
@onready var aim_indicator = $AbilityIndicator 
# REFERÊNCIA NOVA
@onready var heal_vfx = $HealVFX

func _ready():
	add_to_group("player")
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	
	if aim_indicator:
		aim_indicator.visible = false
	
	# Configuração inicial do VFX
	if heal_vfx:
		heal_vfx.visible = false

func _physics_process(delta):
	# 1. Cooldowns
	if honey_current_cooldown > 0:
		honey_current_cooldown -= delta
	
	update_hud_cooldowns()

	# 2. Máquina de Estados de Input
	if is_aiming_skill_1:
		handle_aiming_logic(delta)
	else:
		handle_movement_logic(delta)
		handle_skill_activation()

	move_and_slide()

# --- LÓGICA DE MOVIMENTO ---

func handle_movement_logic(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var player_velocity = input_dir * speed
	
	# Soma forças
	velocity = player_velocity + external_velocity
	external_velocity = external_velocity.move_toward(Vector2.ZERO, 300 * delta)
	
	if input_dir.length() > 0:
		sprite.play("run")
		if input_dir.x != 0:
			sprite.flip_h = input_dir.x < 0
	else:
		sprite.play("idle")

func apply_rope_pull(pull_vector: Vector2):
	external_velocity = pull_vector

# --- LÓGICA DE SKILLS E CURA ---

func handle_skill_activation():
	# Skill 1 (Mel)
	if Input.is_action_just_pressed("skill_1"):
		if honey_current_cooldown <= 0:
			start_aiming()
		else:
			print("Habilidade em Cooldown!")
	
	# Ação de Cura (Espaço)
	if Input.is_action_pressed("action"):
		start_healing_action()
	else:
		stop_healing_action()

func start_healing_action():
	is_healing = true
	
	# Animação do Monge
	if sprite.animation != "heal":
		sprite.play("heal")
	
	# Efeito Visual de Cura
	play_continuous_heal_vfx()
	
	# Aplica Cura (lógica simulada por frame, idealmente multiplicada por delta se estiver no process)
	# Como esta função é chamada todo frame pelo _physics_process (via handle_skill_activation),
	# calculamos o tick aqui.
	var delta = get_physics_process_delta_time()
	var heal_tick = 30.0 * delta # Usando valor fixo de heal_amount = 30.0
	
	# Cura a si mesmo
	heal_self(heal_tick)
	
	# Cura Urso (se vivo)
	if is_instance_valid(bear_node):
		if not bear_node.is_downed:
			bear_node.receive_heal_tick(heal_tick)
		else:
			bear_node.stop_heal_vfx()

func stop_healing_action():
	if is_healing:
		is_healing = false
		sprite.play("idle")
		stop_heal_vfx()
		
		if is_instance_valid(bear_node):
			bear_node.stop_heal_vfx()

# --- VFX DE CURA (NOVO) ---

func play_continuous_heal_vfx():
	if heal_vfx:
		heal_vfx.visible = true
		if not heal_vfx.is_playing() or heal_vfx.animation != heal_animation_name:
			heal_vfx.play(heal_animation_name)

func stop_heal_vfx():
	if heal_vfx:
		heal_vfx.visible = false
		heal_vfx.stop()
	# Reseta cor
	sprite.modulate = Color.WHITE

# --- MIRA ---

func start_aiming():
	is_aiming_skill_1 = true
	if aim_indicator: aim_indicator.visible = true

func cancel_aiming():
	is_aiming_skill_1 = false
	if aim_indicator: aim_indicator.visible = false

func handle_aiming_logic(delta):
	handle_movement_logic(delta)
	
	var mouse_pos = get_global_mouse_position()
	var dist = global_position.distance_to(mouse_pos)
	var dir = global_position.direction_to(mouse_pos)
	
	var target_pos = mouse_pos
	if dist > honey_throw_range:
		target_pos = global_position + (dir * honey_throw_range)
	
	if aim_indicator:
		aim_indicator.global_position = target_pos
	
	if Input.is_action_just_pressed("mouse_left"):
		cast_honey_pot(target_pos)
		cancel_aiming()
		
	if Input.is_action_just_pressed("mouse_right") or Input.is_action_just_pressed("skill_1"):
		cancel_aiming()

func cast_honey_pot(target_pos):
	honey_current_cooldown = honey_cooldown_time
	if honey_projectile_scene:
		var pot = honey_projectile_scene.instantiate()
		get_tree().current_scene.add_child(pot)
		pot.launch(global_position, target_pos)

func update_hud_cooldowns():
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_skill_cooldowns"):
		hud.update_skill_cooldowns(honey_current_cooldown, honey_cooldown_time)

# --- VIDA E DANO ---

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

func receive_heal_tick(amount):
	heal_self(amount)
	play_continuous_heal_vfx()

func heal_self(amount):
	if current_hp < max_hp:
		current_hp = min(current_hp + amount, max_hp)
		hp_bar.value = current_hp
		# Tintura verde suave (se não estiver piscando de dano)
		if not is_invincible:
			sprite.modulate = Color(0.8, 1.0, 0.8)

func get_movement_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
