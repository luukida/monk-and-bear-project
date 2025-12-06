extends Control

func _ready():
	# Focus the start button so you can use keyboard immediately
	$VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed():
	# Loads your renamed gameplay scene
	get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")

func _on_settings_button_pressed():
	# We will create this scene in Step 3
	get_tree().change_scene_to_file("res://Scenes/settings_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
