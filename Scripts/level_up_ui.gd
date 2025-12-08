extends CanvasLayer

# EXPORT TWO TEMPLATES NOW
@export var stat_card_template: PackedScene # Drag 'stat_card.tscn' here
@export var skill_card_template: PackedScene # Drag 'bear_skill_card.tscn' here
@export var monk_card_template: PackedScene

@onready var container = $HBoxContainer 
@onready var sfx_player = $LevelUpSFX

func _ready():
	visible = false
	GameManager.show_upgrade_options.connect(display_options)
	process_mode = Node.PROCESS_MODE_ALWAYS

func display_options(options: Array[UpgradeItem]):
	visible = true
	if sfx_player: sfx_player.play()
	
	for child in container.get_children():
		child.queue_free()
	
	for item in options:
		var card_scene = stat_card_template
		
		# LOGIC TO CHOOSE TEMPLATE
		if item.type == UpgradeItem.CardType.SKILL:
			if item.target == "bear":
				card_scene = skill_card_template
			elif item.target == "monk":
				card_scene = monk_card_template # Use Blue Card
			
		var card = card_scene.instantiate()
		container.add_child(card)
		
		card.set_card_data(item)
		card.card_selected.connect(_on_card_selected)

func _on_card_selected(upgrade: UpgradeItem):
	var main_node = get_tree().current_scene
	if main_node.has_method("apply_upgrade"):
		main_node.apply_upgrade(upgrade)
	
	visible = false
