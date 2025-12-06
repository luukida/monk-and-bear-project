extends Node2D

# Sinais para a UI
signal wave_changed(wave_index, wave_name)
signal time_updated(time_text)

# Lista de Ondas
@export var waves: Array[WaveData] = []

# Referências
@onready var spawn_timer = $SpawnTimer
@onready var wave_timer = $WaveTimer

var current_wave_index = -1
var current_wave_data: WaveData = null

func _ready():
	# Delay inicial
	await get_tree().create_timer(0.7).timeout
	start_next_wave()

func _process(delta):
	if not wave_timer.is_stopped():
		time_updated.emit(format_time(wave_timer.time_left))

func start_next_wave():
	current_wave_index += 1
	
	# Vitória
	if current_wave_index >= waves.size():
		print("GAME OVER! YOU SURVIVED!")
		spawn_timer.stop()
		wave_timer.stop()
		time_updated.emit("00:00")
		return 
		
	current_wave_data = waves[current_wave_index]
	
	# Nome da Onda
	var wave_name = "Wave " + str(current_wave_index + 1)
	if current_wave_data.get("wave_message") and current_wave_data.wave_message != "":
		wave_name = current_wave_data.wave_message
		
	print("Starting sequence: ", wave_name)
	
	# 1. Avisa a UI (Começa a animação de texto de 3.5s)
	wave_changed.emit(current_wave_index + 1, wave_name)
	
	# 2. Atualiza o texto do timer para "00:XX" (para ele aparecer pronto)
	time_updated.emit(format_time(current_wave_data.duration))
	
	# 3. Espera exatos 3.5 segundos (0.5 In + 2.0 Wait + 1.0 Out)
	await get_tree().create_timer(2.0).timeout
	
	# 4. COMEÇA A ONDA (Spawn e Timer)
	spawn_timer.wait_time = current_wave_data.spawn_interval
	spawn_timer.start()
	
	wave_timer.wait_time = current_wave_data.duration
	wave_timer.start()

func _on_wave_timer_timeout():
	start_next_wave()

func _on_spawn_timer_timeout():
	if current_wave_data and current_wave_data.get("enemies") and current_wave_data.enemies.size() > 0:
		var selected_enemy = pick_weighted_enemy(current_wave_data.enemies)
		if selected_enemy:
			var main = get_parent()
			if main.has_method("spawn_enemy"):
				main.spawn_enemy(selected_enemy)

func format_time(seconds_val: float) -> String:
	var minutes = floor(seconds_val / 60)
	var seconds = int(seconds_val) % 60
	return "%02d:%02d" % [minutes, seconds]

func pick_weighted_enemy(enemy_list: Array) -> PackedScene:
	var total_weight = 0.0
	for info in enemy_list:
		total_weight += info.weight
	
	var random_val = randf() * total_weight
	var current_sum = 0.0
	
	for info in enemy_list:
		current_sum += info.weight
		if random_val <= current_sum:
			return info.enemy
	return null
