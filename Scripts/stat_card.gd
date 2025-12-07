extends Button

# Data holder
var upgrade_data: UpgradeItem

# Signal to main UI
signal card_selected(upgrade)

# --- ANIMATION SETTINGS ---
@export var hover_scale: Vector2 = Vector2(1.15, 1.15)
@export var pressed_scale: Vector2 = Vector2(0.95, 0.95)
@export var animation_time: float = 0.3

func _ready():
	# 1. Setup Pivot to Center (Crucial for scaling from the middle)
	pivot_offset = size / 2
	resized.connect(func(): pivot_offset = size / 2)
	
	# 2. Connect Visual Signals
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	# 3. Connect Logic Signal
	pressed.connect(_on_pressed)

func set_card_data(item: UpgradeItem):
	upgrade_data = item
	
	# Update Nodes with new paths
	$TitlePath2D.text = item.title
	$Icon.texture = item.icon
	$DescriptionLabel.text = item.description

# --- VISUALS ---

func _on_hover_enter():
	if disabled: return
	animate_scale(hover_scale)

func _on_hover_exit():
	animate_scale(Vector2.ONE)

func _on_button_down():
	animate_scale(pressed_scale)

func _on_button_up():
	# Return to hover scale if still hovering, else normal
	if is_hovered():
		animate_scale(hover_scale)
	else:
		animate_scale(Vector2.ONE)

func _on_pressed():
	card_selected.emit(upgrade_data)

# Helper for clean Tweens
func animate_scale(target_val: Vector2):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_val, animation_time)
