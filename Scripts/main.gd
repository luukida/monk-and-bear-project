extends Node2D


func _ready():
	
	MusicManager.play_battle_music()
	# Garante que as referências existam antes de conectar
	if has_node("Monk") and has_node("Bear"):
		var monk = $Monk
		var bear = $Bear
		
		# Faz a conexão vital: Monge conhece Urso, Urso conhece Monge.
		# Isso permite que a IA funcione sem buscar "get_tree()" toda hora.
		monk.bear_node = bear
		bear.monk_node = monk

# Função chamada pelo WaveManager
func spawn_enemy(enemy_scene: PackedScene):
	var enemy = enemy_scene.instantiate()
	
	# Lógica de Posição Circular (Mantida igual)
	if has_node("Monk"):
		var player_pos = $Monk.global_position
		var random_angle = randf() * TAU
		var distance = 600.0
		var spawn_pos = player_pos + Vector2(cos(random_angle), sin(random_angle)) * distance
		enemy.global_position = spawn_pos
	
	add_child(enemy)

func apply_upgrade(upgrade: UpgradeItem):
	_apply_upgrade_logic(upgrade)
	
	get_tree().paused = false

func _apply_upgrade_logic(upgrade: UpgradeItem):
	var target_node = null
	
	match upgrade.target:
		"bear": target_node = $Bear
		"monk": target_node = $Monk
	
	if not target_node: return

	# CHECK TYPE
	if upgrade.type == UpgradeItem.CardType.STAT:
		# (Existing Stat Logic...)
		if upgrade.property_name in target_node:
			var old_val = target_node.get(upgrade.property_name)
			target_node.set(upgrade.property_name, old_val + upgrade.amount)
			print("Applied Stat: ", upgrade.title)
			
	elif upgrade.type == UpgradeItem.CardType.SKILL:
		print("!!! UNLOCKING SKILL: ", upgrade.title, " !!!")
		
		# --- BEAR SKILLS ---
		if upgrade.target == "bear":
			if upgrade.property_name == "unlock_lunge":
				target_node.can_lunge = true
				print("Bear learned Lunge!")
			
			if upgrade.property_name == "unlock_charge":
				target_node.can_charge = true
				print("Bear learned Charge!")
		
