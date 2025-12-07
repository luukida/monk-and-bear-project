extends "res://Scripts/base_enemy.gd"

@export_group("Gnoll Stats")
@export var attack_range = 280.0   
@export var projectile_scene: PackedScene 

func behavior_chase():
	if not is_instance_valid(target):
		super.behavior_chase()
		return

	var dist = global_position.distance_to(target.global_position)
	
	# Lógica Simplificada: Chegou no alcance? Para e atira.
	if dist <= attack_range:
		# ATACA (Torreta)
		velocity = Vector2.ZERO
		sprite.play("idle")
		update_orientation(target.global_position)
		start_telegraph() 
		
	else:
		# SEGUE (Corre para alcançar)
		var dir = global_position.direction_to(target.global_position)
		velocity = dir * speed
		sprite.play("run")
		update_orientation(target.global_position)

# Sobrescreve o ataque para atirar
func start_attack():
	current_state = State.ATTACK
	if telegraph: telegraph.visible = false
	
	sprite.play("attack")
	sprite.frame = 0

# Spawna o projétil no frame certo
func apply_damage_snapshot():
	if projectile_scene:
		var bullet = projectile_scene.instantiate()
		bullet.damage = damage 
		get_tree().current_scene.add_child(bullet)
		
		# --- KEY FIX: FIRE WHERE YOU LOOK ---
		# Instead of "target.global_position" (Aim Bot),
		# we use "hitbox.rotation" (Where the telegraph is pointing).
		
		var aim_dir = Vector2.RIGHT.rotated(hitbox.rotation)
		var target_pos = global_position + (aim_dir * 1000.0) # Project a point far away
		
		bullet.launch(global_position, target_pos)

# Usa a lógica de tempo do pai para o telegraph
func start_telegraph():
	super.start_telegraph()

func update_orientation(target_pos: Vector2):
	# 1. Let Base Enemy handle the body flipping (Left/Right)
	super.update_orientation(target_pos)
	
	# 2. OVERRIDE the Hitbox (Telegraph) to aim 360 degrees
	# This ensures the red arrow points straight at the target
	var dir = global_position.direction_to(target_pos)
	hitbox.rotation = dir.angle()
	
	# 3. Fix Offset Flipping
	# The base script mirrors the X position when facing left. 
	# We undo that for the telegraph because we are rotating it manually.
	if telegraph:
		telegraph.position.x = abs(telegraph.position.x)
