extends Control

@onready var buttons_container = $VBoxContainer
@onready var selector = $Selector
@onready var selector_left = $Selector/Left
@onready var selector_right = $Selector/Right

func _ready():
	if MusicManager:
		MusicManager.play_menu_music()
	
	# 1. Connect signals for ALL buttons automatically
	for btn in buttons_container.get_children():
		if btn is Button:
			# Mouse Hover
			btn.mouse_entered.connect(func(): _on_button_focused(btn))
			# Keyboard Focus
			btn.focus_entered.connect(func(): _on_button_focused(btn))
			
			# Connect click events (Keep your existing logic links here)
			#if btn.name == "StartButton": btn.pressed.connect(_on_start_button_pressed)
			#elif btn.name == "SettingsButton": btn.pressed.connect(_on_settings_button_pressed)
			#elif btn.name == "QuitButton": btn.pressed.connect(_on_quit_button_pressed)

	# 2. Initialize Selection
	# Wait one frame for UI layout to calculate positions
	await get_tree().process_frame
	var first_btn = buttons_container.get_child(0)
	#first_btn.grab_focus()
	_on_button_focused(first_btn)

func _on_button_focused(btn: Button):
	if not selector: return
	
	# The "Match Rect" Strategy
	# We simply tween the Selector's Position AND Size to match the button exactly.
	# The Anchors inside the Selector will handle the Left/Right sprites automatically.
	
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 1. Match Position (Top-Left corner)
	tween.tween_property(selector, "global_position", btn.global_position, 0.2)
	
	# 2. Match Size (Width/Height)
	# This ensures the brackets expand for "Settings" and shrink for "Quit"
	tween.tween_property(selector, "size", btn.size, 0.2)
	
	# Optional: Reset scale punch for "Juice"
	selector_left.scale = Vector2(1.2, 1.2)
	selector_right.scale = Vector2(1.2, 1.2)
	tween.tween_property(selector_left, "scale", Vector2.ONE, 0.2)
	tween.tween_property(selector_right, "scale", Vector2.ONE, 0.2)

# --- YOUR EXISTING BUTTON FUNCTIONS ---
func _on_start_button_pressed():
	# Optional: Stop music when game starts
	# MusicManager.stop_music() 
	get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")

func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/settings_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
