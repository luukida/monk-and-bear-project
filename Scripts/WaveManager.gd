extends Node2D

signal wave_changed(wave_index, wave_name)
signal time_updated(time_text)

@export var waves: Array[WaveData] = []

@onready var spawn_timer = $SpawnTimer
@onready var wave_timer = $WaveTimer

var current_wave_index = -1
var current_wave_data: WaveData = null

func _ready():
	# Wait a moment for the game to initialize
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
	
	if current_wave_index >= waves.size():
		print("ALL WAVES COMPLETE! BOSS COMING SOON...")
		spawn_timer.stop()
		wave_timer.stop()
		time_updated.emit("VICTORY?")
		return 
		
	current_wave_data = waves[current_wave_index]
	
	var wave_name = "WAVE " + str(current_wave_index + 1)
	if current_wave_data.wave_message != "":
		wave_name = current_wave_data.wave_message
		
	print("Starting: ", wave_name)
	wave_changed.emit(current_wave_index + 1, wave_name)
	
	spawn_timer.wait_time = current_wave_data.spawn_interval
	spawn_timer.start()
	
	wave_timer.wait_time = current_wave_data.duration
	wave_timer.start()

func _on_wave_timer_timeout():
	start_next_wave()

# Inside _on_spawn_timer_timeout
func _on_spawn_timer_timeout():
	# Update to check the Array size
	if current_wave_data and current_wave_data.enemies.size() > 0:
		var selected_enemy = pick_weighted_enemy(current_wave_data.enemies)
		if selected_enemy:
			var main = get_parent()
			if main.has_method("spawn_enemy"):
				main.spawn_enemy(selected_enemy)

# Update the algorithm to read the Array
func pick_weighted_enemy(enemy_list: Array[SpawnInfo]) -> PackedScene:
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
