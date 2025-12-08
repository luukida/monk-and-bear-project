extends Control

@onready var icon_rect = $Icon
@onready var cooldown_bar = $CooldownOverlay
@onready var key_label = $KeyLabel
@onready var timer_label = $TimerLabel # Ensure you added this Label node in the scene!

# Tween for the flashing effect
var active_tween: Tween

func setup(icon_texture: Texture2D, key_text: String = ""):
	if icon_texture:
		icon_rect.texture = icon_texture
	
	cooldown_bar.value = 0
	
	# Hide label if no key is assigned (for Bear skills)
	if key_text == "":
		key_label.visible = false
	else:
		key_label.text = key_text
		key_label.visible = true
		
	if timer_label:
		timer_label.visible = false

func update_cooldown(current_timer: float, max_cooldown: float):
	if current_timer > 0 and max_cooldown > 0:
		var percentage = (current_timer / max_cooldown) * 100
		cooldown_bar.value = percentage
		
		if timer_label:
			timer_label.visible = true
			timer_label.text = "%.1f" % current_timer
	else:
		cooldown_bar.value = 0
		if timer_label:
			timer_label.visible = false

# --- VISUAL FEEDBACK (Flashing) ---
func set_active_state(is_active: bool):
	if is_active:
		# If already pulsing, don't restart
		if active_tween and active_tween.is_running(): return
		
		# Start Pulsing (Yellow Glow)
		active_tween = create_tween().set_loops()
		active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Pulse Color (White -> Yellow -> White)
		active_tween.tween_property(icon_rect, "modulate", Color(1.5, 1.5, 0.5), 0.3)
		active_tween.tween_property(icon_rect, "modulate", Color.WHITE, 0.3)
		
		# Pulse Scale (Subtle heartbeat)
		active_tween.parallel().tween_property(icon_rect, "scale", Vector2(1.1, 1.1), 0.3)
		active_tween.parallel().tween_property(icon_rect, "scale", Vector2(1.0, 1.0), 0.3)
		
	else:
		# Stop Pulsing
		if active_tween:
			active_tween.kill()
			active_tween = null
		
		# Reset to normal
		icon_rect.modulate = Color.WHITE
		icon_rect.scale = Vector2.ONE
