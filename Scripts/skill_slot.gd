extends Control

@onready var icon_rect = $Icon
@onready var cooldown_bar = $CooldownOverlay
@onready var key_label = $KeyLabel

func setup(icon_texture: Texture2D, key_text: String):
	icon_rect.texture = icon_texture
	key_label.text = key_text
	cooldown_bar.value = 0

func update_cooldown(current_timer: float, max_cooldown: float):
	if current_timer > 0:
		# Converte o tempo restante em porcentagem (0 a 100)
		var percentage = (current_timer / max_cooldown) * 100
		cooldown_bar.value = percentage
	else:
		cooldown_bar.value = 0
