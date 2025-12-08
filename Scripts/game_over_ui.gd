extends CanvasLayer

@onready var info_label = $InfoLabel
@onready var restart_button = $HBoxContainer/RestartScroll/RestartButton
# 1. New Reference
@onready var sfx_player = $GameOverSFX 

func _ready():
	visible = false
	GameManager.game_over.connect(_on_game_over)
	process_mode = Node.PROCESS_MODE_ALWAYS 

func _on_game_over(wave: int):
	visible = true
	info_label.text = "You survived until Wave " + str(wave)
	
	# 2. Stop the Battle Music
	MusicManager.stop_music()
	
	# 3. Play Defeat Sound
	if sfx_player:
		sfx_player.play()
	
	restart_button.grab_focus()

func _on_restart_button_pressed():
	GameManager.reset_progress()
	get_tree().paused = false
	
	# 4. Restart Battle Music (Optional, but good practice)
	# If your main scene's _ready() handles this, you might not need it here.
	# But just in case:
	MusicManager.play_battle_music()
	
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	GameManager.reset_progress()
	get_tree().paused = false
	
	# 5. Switch back to Menu Music
	MusicManager.play_menu_music()
	
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
