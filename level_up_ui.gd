extends CanvasLayer

# Precisamos do modelo da carta para criar 3 cópias
@export var card_template: PackedScene # Arraste UpgradeCard.tscn para cá

@onready var container = $HBoxContainer # Onde as cartas vão ficar

func _ready():
	# Começa escondido
	visible = false
	
	# Conecta no sinal do GameManager para saber quando abrir
	# Nota: GameManager precisa ser uma Cena ou Autoload acessível
	GameManager.show_upgrade_options.connect(display_options)

func display_options(options: Array[UpgradeItem]):
	# 1. Mostra a tela
	visible = true
	
	# 2. Limpa cartas antigas (se houver)
	for child in container.get_children():
		child.queue_free()
	
	# 3. Cria as novas cartas
	for item in options:
		var card = card_template.instantiate()
		container.add_child(card)
		
		# Preenche os dados
		card.set_card_data(item)
		
		# Conecta o clique da carta
		card.card_selected.connect(_on_card_selected)

func _on_card_selected(upgrade: UpgradeItem):
	# 1. Aplica o upgrade (Chama o Main para resolver)
	# Como a UI é filha do Main (provavelmente), podemos chamar o pai ou usar grupos/sinais
	# Vamos usar o método mais seguro: Buscar o nó Main na árvore.
	var main_node = get_tree().current_scene
	if main_node.has_method("apply_upgrade"):
		main_node.apply_upgrade(upgrade)
	
	# 2. Fecha a tela
	visible = false
