extends CanvasLayer

@onready var xp_bar = $ProgressBar
@onready var level_label = $Label 

func _ready():
	# Conecta os sinais do GameManager
	if not GameManager.xp_changed.is_connected(update_xp_bar):
		GameManager.xp_changed.connect(update_xp_bar)
		
	if not GameManager.level_up.is_connected(update_level_display):
		GameManager.level_up.connect(update_level_display)
	
	# ATUALIZAÇÃO INICIAL FORÇADA
	# Garante que ele pegue os valores atuais assim que o jogo começa
	update_xp_bar(GameManager.current_xp, GameManager.required_xp)
	update_level_display(GameManager.level)

func update_xp_bar(current, required):
	xp_bar.max_value = required
	xp_bar.value = current

func update_level_display(new_level):
	print("HUD: Atualizando para Nível ", new_level) # Debug no Output
	
	if level_label:
		level_label.text = "Lv. " + str(new_level)
	else:
		print("ERRO: HUD não encontrou o nó $Label!")
