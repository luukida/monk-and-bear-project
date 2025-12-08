extends Control

@onready var music_slider = $VBoxContainer/MusicSlider
@onready var sfx_slider = $VBoxContainer/SFXSlider
@onready var small_scroll_main_menu = $HBoxContainer/SmallScrollMainMenu
@onready var quit_to_title_button = $HBoxContainer/SmallScrollMainMenu/QuitToTitleButton


# False = Main Menu Mode (Change Scene)
# True = Gameplay Mode (Close Popup)
var is_gameplay_popup: bool = false 

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var music_idx = AudioServer.get_bus_index("Music")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_idx))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx))
	
	# --- VISIBILITY LOGIC ---
	# Only show "Quit to Title" if we are actually IN the game (Popup Mode)
	if is_gameplay_popup:
		small_scroll_main_menu.visible = true
		quit_to_title_button.visible = true
	else:
		small_scroll_main_menu.visible = false
		quit_to_title_button.visible = false

func _on_music_slider_value_changed(value):
	var idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _on_sfx_slider_value_changed(value):
	var idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _on_back_button_pressed():
	if is_gameplay_popup:
		# Gameplay Mode: Just close the popup and resume
		get_tree().paused = false
		if get_parent() is CanvasLayer:
			get_parent().queue_free()
		else:
			queue_free()
	else:
		# Main Menu Mode: Go back to the main menu buttons
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

# --- NEW FUNCTION ---
func _on_quit_to_title_button_pressed():
	# 1. Reset Run Progress (XP, Level, etc.)
	GameManager.reset_progress()
	
	# 2. Unpause (Crucial before changing scenes!)
	get_tree().paused = false
	
	# 3. Switch Music back to Menu Theme
	if MusicManager:
		MusicManager.play_menu_music()
	
	# 4. Go to Title Screen
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
