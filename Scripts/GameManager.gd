extends Node

# Configuração de XP
const XP_BASE = 5
const XP_FACTOR = 1.2

# Começando do 0 como você pediu
var level = 0
var current_xp = 0
var required_xp = 0

# BANCO DE DADOS DE UPGRADES
@export var all_upgrades: Array[UpgradeItem] = []

# Sinais
signal xp_changed(current, required)
signal level_up(new_level)
signal show_upgrade_options(options) 

func _ready():
	# Delay de segurança para garantir que a Main carregou antes de emitir sinais iniciais
	await get_tree().create_timer(0.1).timeout
	calculate_required_xp()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		if not event.echo: 
			print("CHEAT: Ganhou 50 XP!")
			gain_xp(50)

func calculate_required_xp():
	# Proteção matemática: se level for 0, usa level 1 na conta para não dar erro ou valor estranho
	# Mas matematicamente pow(1.2, -1) funciona (dá 0.83), então ok.
	required_xp = round(XP_BASE * pow(XP_FACTOR, level))
	
	xp_changed.emit(current_xp, required_xp)
	# Emite o sinal aqui também para garantir que o HUD atualize ao iniciar o jogo
	level_up.emit(level) 

func gain_xp(amount):
	current_xp += amount
	
	# Loop para caso ganhe muito XP de uma vez (ex: matar boss)
	while current_xp >= required_xp:
		current_xp -= required_xp
		level_up_process()
		
	xp_changed.emit(current_xp, required_xp)

func level_up_process():
	level += 1
	print("LEVEL UP! Nível ", level)
	
	# Recalcula o próximo alvo
	calculate_required_xp()
	
	# --- A CORREÇÃO ESTÁ AQUI ---
	# Avisa o HUD que o nível mudou!
	level_up.emit(level)
	
	# 1. Sorteia cartas
	var options = get_random_upgrades(3)
	
	# 2. Pausa
	get_tree().paused = true
	
	# 3. Abre a UI de Cartas
	show_upgrade_options.emit(options)

func get_random_upgrades(amount: int) -> Array[UpgradeItem]:
	var pool = all_upgrades.duplicate()
	var selected: Array[UpgradeItem] = []
	pool.shuffle()
	var grab_count = min(amount, pool.size())
	for i in range(grab_count):
		selected.append(pool[i])
	return selected
