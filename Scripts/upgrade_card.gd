extends Button

# Variável para guardar os dados deste card
var upgrade_data: UpgradeItem

# Sinal customizado para avisar a UI principal que este card foi clicado
signal card_selected(upgrade)

func _ready():
	pressed.connect(_on_pressed)

func set_card_data(item: UpgradeItem):
	upgrade_data = item
	
	# Preenche os textos e imagens
	# Ajuste os caminhos ($VBoxContainer/Label...) conforme sua hierarquia real
	$TitlePath2D.text = item.title
	$Icon.texture = item.icon
	$DescriptionLabel.text = item.description

func _on_pressed():
	# Emite o sinal passando os dados para quem estiver ouvindo (A UI Principal)
	card_selected.emit(upgrade_data)
