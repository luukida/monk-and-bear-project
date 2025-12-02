extends Node2D

# Lista de inimigos possíveis.
# No Inspector, defina o tamanho (Size) e arraste as cenas (Grunt.tscn, Brute.tscn) para cá.
@export var enemy_scenes: Array[PackedScene] 

func _ready():
	# Garante que as referências existam antes de conectar
	if has_node("Monk") and has_node("Bear"):
		var monk = $Monk
		var bear = $Bear
		
		# Faz a conexão vital: Monge conhece Urso, Urso conhece Monge.
		# Isso permite que a IA funcione sem buscar "get_tree()" toda hora.
		monk.bear_node = bear
		bear.monk_node = monk
	
	# Conecta o sinal do Timer (se não tiver conectado via interface)
	if has_node("SpawnTimer"):
		if not $SpawnTimer.timeout.is_connected(_on_spawn_timer_timeout):
			$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)
	
	# Conecta o sinal de level up do GameManager
	# (Supondo que vamos criar a UI de Level Up depois, por enquanto vamos testar a lógica)
	# GameManager.show_upgrade_options.connect(_on_show_upgrade_options) 
	#pass

func _on_spawn_timer_timeout():
	# Segurança: Se a lista estiver vazia, não faz nada para não travar o jogo
	if enemy_scenes.is_empty():
		return
	
	# 1. Escolhe um inimigo aleatório da lista
	var random_index = randi() % enemy_scenes.size()
	var selected_scene = enemy_scenes[random_index]
	
	var enemy = selected_scene.instantiate()
	
	# 2. Define a Posição de Spawn
	# Gera uma posição circular ao redor do Monge, fora da tela
	if has_node("Monk"):
		var player_pos = $Monk.global_position
		var random_angle = randf() * TAU # TAU é 2*PI (360 graus)
		var distance = 600.0 # Raio de spawn (ajuste se os inimigos aparecerem na tela)
		
		var spawn_pos = player_pos + Vector2(cos(random_angle), sin(random_angle)) * distance
		enemy.global_position = spawn_pos
	
	# 3. Adiciona à cena
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
