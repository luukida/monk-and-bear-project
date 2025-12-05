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
	if projectile_scene and is_instance_valid(target):
		var bullet = projectile_scene.instantiate()
		bullet.damage = damage 
		get_tree().current_scene.add_child(bullet)
		bullet.launch(global_position, target.global_position)

# Usa a lógica de tempo do pai para o telegraph
func start_telegraph():
	super.start_telegraph()
