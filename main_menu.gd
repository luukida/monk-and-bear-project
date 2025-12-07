extends Control

func _ready():
	$VBoxContainer/StartButton.grab_focus()
	
	# Start the music!
	# (Since MusicManager is global, we can call it from anywhere)
	MusicManager.play_menu_music()

func _on_start_button_pressed():
	# Optional: Stop music when game starts
	# MusicManager.stop_music() 
	
	get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")

func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/settings_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
