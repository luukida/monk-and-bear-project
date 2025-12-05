extends Node2D

# Sinais para avisar a UI (ex: "WAVE 2 COMEÇOU!")
signal wave_changed(wave_index, wave_name)

# Lista de Ondas (Arraste os arquivos .tres aqui)
@export var waves: Array[WaveData] = []

# Referências
@onready var spawn_timer = $SpawnTimer
@onready var wave_timer = $WaveTimer

var current_wave_index = -1
var current_wave_data: WaveData = null

func _ready():
	# Começa o jogo com um pequeno delay
	await get_tree().create_timer(1.0).timeout
	start_next_wave()

func start_next_wave():
	current_wave_index += 1
	
	# Chegou no fim das ondas? (Vitória ou Loop Infinito)
	if current_wave_index >= waves.size():
		print("FIM DO JOGO! VOCÊ SOBREVIVEU!")
		spawn_timer.stop()
		return # Aqui você chamaria a tela de Vitória
		
	# Carrega os dados da nova onda
	current_wave_data = waves[current_wave_index]
	
	print("Iniciando Onda: ", current_wave_index + 1)
	emit_signal("wave_changed", current_wave_index + 1, "Onda " + str(current_wave_index + 1))
	
	# Configura os Timers
	spawn_timer.wait_time = current_wave_data.spawn_interval
	spawn_timer.start()
	
	wave_timer.wait_time = current_wave_data.duration
	wave_timer.start()

func _on_wave_timer_timeout():
	# O tempo da onda acabou, chama a próxima
	start_next_wave()

func _on_spawn_timer_timeout():
	# Lógica de Spawn (Chamando o Main para spawnar)
	if current_wave_data and current_wave_data.possible_enemies.size() > 0:
		var enemy_scene = current_wave_data.possible_enemies.pick_random()
		
		# Acha o Main (pai) e manda spawnar
		var main = get_parent()
		if main.has_method("spawn_enemy"):
			main.spawn_enemy(enemy_scene)
