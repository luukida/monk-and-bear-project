extends Control

@onready var icon_rect = $Icon
@onready var cooldown_bar = $CooldownOverlay
@onready var key_label = $KeyLabel
@onready var timer_label = $TimerLabel

func setup(icon_texture: Texture2D, key_text: String):
	icon_rect.texture = icon_texture
	key_label.text = key_text
	cooldown_bar.value = 0
	if timer_label:
		timer_label.text = ""
		timer_label.visible = false

func update_cooldown(current_timer: float, max_cooldown: float):
	if current_timer > 0:
		var percentage = (current_timer / max_cooldown) * 100
		cooldown_bar.value = percentage
		
		if timer_label:
			timer_label.visible = true
			# CHANGED: Formats as "3.5", "0.4", etc.
			timer_label.text = "%.1f" % current_timer
	else:
		cooldown_bar.value = 0
		if timer_label:
			timer_label.visible = false
