extends "res://Scripts/base_enemy.gd"

@export_group("Stalker Behavior")
@export var flee_speed: float = 300.0 
@export var bear_detection_range: float = 350.0 
@export var bear_safe_distance: float = 500.0
@export var stalk_duration: float = 2.0 
@export var bravery_chance: float = 0.25 

var is_fleeing = false
var is_stalking = false
var is_brave = false 
var stalk_timer = 0.0

func _ready():
	super._ready()
	# Começa transparente (40%)
	modulate.a = 0.4 

func select_target() -> Node2D:
	if is_instance_valid(player_ref):
		return player_ref
	return null

func behavior_chase():
	var delta = get_process_delta_time()
	
	# Se já decidiu ser BRAVO, vai pro ataque
	if is_brave:
		sprite.speed_scale = 1.0
		super.behavior_chase()
		return

	# --- LÓGICA DE MEDO ---
	
	var dist_to_bear = INF
	if is_instance_valid(bear_ref) and not bear_ref.get("is_downed"):
		dist_to_bear = global_position.distance_to(bear_ref.global_position)
	
	if dist_to_bear < bear_detection_range and not is_fleeing and not is_stalking:
		
		# MOMENTO DA VERDADE
		if randf() < bravery_chance:
			is_brave = true
			
			# MUDANÇA: Removemos a tinta vermelha.
			# Ele fica bravo, mas mantém a cor original (Branco Transparente)
			modulate = Color(1, 1, 1, 0.4) 
			
			#print("Stalker escolheu VIOLÊNCIA!")
			return 
		else:
			is_fleeing = true
			#print("Stalker escolheu FUGA!")

	# --- ESTADO: FUGINDO ---
	if is_fleeing:
		if dist_to_bear > bear_safe_distance:
			is_fleeing = false
			is_stalking = true
			stalk_timer = stalk_duration
			sprite.speed_scale = 1.0 
			return 
			
		var flee_dir = (global_position - bear_ref.global_position).normalized()
		velocity = flee_dir * flee_speed
		sprite.play("run")
		sprite.speed_scale = 2.5 
		update_orientation(global_position + flee_dir)
		return

	# --- ESTADO: OBSERVANDO ---
	if is_stalking:
		if dist_to_bear < (bear_detection_range * 0.5): 
			is_stalking = false
			return 

		stalk_timer -= delta
		velocity = Vector2.ZERO 
		sprite.play("idle")
		sprite.speed_scale = 1.0
		
		if is_instance_valid(player_ref):
			update_orientation(player_ref.global_position) 
			
		if stalk_timer <= 0:
			is_stalking = false
		
		return 

	sprite.speed_scale = 1.0 
	super.behavior_chase()

# --- COMBATE (VISIBILIDADE) ---

func start_attack():
	# Fica 100% visível (Branco Sólido) apenas no ataque
	modulate = Color.WHITE 
	
	super.start_attack()

func _on_animation_finished():
	super._on_animation_finished() 
	
	if sprite.animation == "attack":
		is_brave = false
		
		# Volta para transparente (Fantasma Branco)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0.4), 0.3)
