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

# Esta função será chamada pela UI quando o jogador clicar num botão
func apply_upgrade(upgrade: UpgradeItem):
	var target_node = null
	
	# Descobre quem é o alvo
	match upgrade.target:
		"bear":
			target_node = $Bear
		"monk":
			target_node = $Monk
	
	if target_node:
		# LÓGICA DINÂMICA (Reflection)
		# Verifica se o urso tem a variável "damage"
		if upgrade.property_name in target_node:
			var old_val = target_node.get(upgrade.property_name)
			
			if upgrade.type == "stat_add":
				# Soma: 35 + 10 = 45
				target_node.set(upgrade.property_name, old_val + upgrade.amount)
				print("Upgrade Aplicado! ", upgrade.property_name, " foi de ", old_val, " para ", target_node.get(upgrade.property_name))
				
		else:
			print("ERRO: Variável ", upgrade.property_name, " não existe no alvo ", upgrade.target)
	
	# Retoma o jogo
	get_tree().paused = false
