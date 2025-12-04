extends CanvasLayer

@onready var xp_bar = $ProgressBar
@onready var level_label = $Label
@onready var slot_honey = $SkillContainer/SlotHoney

func _ready():
	# Conecta os sinais do GameManager
	if not GameManager.xp_changed.is_connected(update_xp_bar):
		GameManager.xp_changed.connect(update_xp_bar)
		
	if not GameManager.level_up.is_connected(update_level_display):
		GameManager.level_up.connect(update_level_display)
	
	# ATUALIZAÇÃO INICIAL FORÇADA
	# Garante que ele pegue os valores atuais assim que o jogo começa
	update_xp_bar(GameManager.current_xp, GameManager.required_xp)

func update_xp_bar(current, required):
	xp_bar.max_value = required
	xp_bar.value = current

func update_level_display(new_level):
	print("HUD: Atualizando para Nível ", new_level) # Debug no Output
	
	if level_label:
		level_label.text = "Lv. " + str(new_level)
	else:
		print("ERRO: HUD não encontrou o nó $Label!")

# Função chamada pelo Monge a cada frame para atualizar a UI
func update_skill_cooldowns(honey_time, honey_max):
	if slot_honey:
		slot_honey.update_cooldown(honey_time, honey_max)
