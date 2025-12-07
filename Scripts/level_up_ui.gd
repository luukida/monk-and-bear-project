extends CanvasLayer

# Precisamos do modelo da carta para criar 3 cópias
@export var card_template: PackedScene 

@onready var container = $HBoxContainer 
@onready var sfx_player = $LevelUpSFX # Reference to the new node

func _ready():
	# Começa escondido
	visible = false
	
	# Conecta no sinal do GameManager para saber quando abrir
	GameManager.show_upgrade_options.connect(display_options)
	
	# Ensure it processes while paused (since leveling pauses the game)
	process_mode = Node.PROCESS_MODE_ALWAYS

func display_options(options: Array[UpgradeItem]):
	# 1. Mostra a tela
	visible = true
	
	# 2. Play Sound
	if sfx_player:
		sfx_player.play()
	
	# 3. Limpa cartas antigas (se houver)
	for child in container.get_children():
		child.queue_free()
	
	# 4. Cria as novas cartas
	for item in options:
		var card = card_template.instantiate()
		container.add_child(card)
		
		# Preenche os dados
		card.set_card_data(item)
		
		# Conecta o clique da carta
		card.card_selected.connect(_on_card_selected)

func _on_card_selected(upgrade: UpgradeItem):
	# 1. Aplica o upgrade (Chama o Main para resolver)
	var main_node = get_tree().current_scene
	if main_node.has_method("apply_upgrade"):
		main_node.apply_upgrade(upgrade)
	
	# 2. Fecha a tela
	visible = false
