extends Control

@onready var music_slider = $VBoxContainer/MusicSlider
@onready var sfx_slider = $VBoxContainer/SFXSlider

func _ready():
	# 1. Get current values so the sliders match reality
	var music_idx = AudioServer.get_bus_index("Music")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	
	# Convert Decibels (Godot's system) to 0-1 (Slider system)
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_idx))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx))

func _on_music_slider_value_changed(value):
	var idx = AudioServer.get_bus_index("Music")
	# Convert 0-1 back to Decibels
	# "linear_to_db(0)" is -infinity (silence), which is what we want
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _on_sfx_slider_value_changed(value):
	var idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _on_back_button_pressed():
	# Return to Main Menu
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
