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
	await get_tree().create_timer(1.0).timeout
	start_next_wave()

func _process(delta):
	if not wave_timer.is_stopped():
		var time_left = wave_timer.time_left
		
		var minutes = floor(time_left / 60)
		var seconds = int(time_left) % 60
		var time_string = "%02d:%02d" % [minutes, seconds]
		
		time_updated.emit(time_string)

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
	
	# MUDANÇA: Texto em Inglês
	var wave_name = "WAVE " + str(current_wave_index + 1)
	
	# Se tiver mensagem customizada no Resource, usa ela (lembre de escrever em inglês no recurso!)
	if current_wave_data.get("wave_message") and current_wave_data.wave_message != "":
		wave_name = current_wave_data.wave_message
		
	print("Starting: ", wave_name)
	
	wave_changed.emit(current_wave_index + 1, wave_name)
	
	spawn_timer.wait_time = current_wave_data.spawn_interval
	spawn_timer.start()
	
	wave_timer.wait_time = current_wave_data.duration
	wave_timer.start()

func _on_wave_timer_timeout():
	start_next_wave()

func _on_spawn_timer_timeout():
	if current_wave_data and current_wave_data.possible_enemies.size() > 0:
		var enemy_scene = current_wave_data.possible_enemies.pick_random()
		var main = get_parent()
		if main.has_method("spawn_enemy"):
			main.spawn_enemy(enemy_scene)
