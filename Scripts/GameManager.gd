extends Node

const XP_BASE = 5
const XP_FACTOR = 1.2

var level = 0
var current_xp = 0
var required_xp = 0

@export var all_upgrades: Array[UpgradeItem] = []

signal xp_changed(current, required)
signal level_up(new_level)
signal show_upgrade_options(options) 

func _ready():
	await get_tree().create_timer(0.1).timeout
	calculate_required_xp()
	
	# ADICIONADO: Emite aqui manualmente só na inicialização
	level_up.emit(level) 

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		if not event.echo: 
			print("CHEAT: Ganhou 50 XP!")
			gain_xp(50)

func calculate_required_xp():
	required_xp = round(XP_BASE * pow(XP_FACTOR, level))
	xp_changed.emit(current_xp, required_xp)
	
	# REMOVIDO: level_up.emit(level)
	# Tiramos daqui para não duplicar quando subir de nível

func gain_xp(amount):
	current_xp += amount
	while current_xp >= required_xp:
		current_xp -= required_xp
		level_up_process()
	xp_changed.emit(current_xp, required_xp)

func level_up_process():
	level += 1
	print("LEVEL UP! Nível ", level)
	
	calculate_required_xp()
	
	# MANTIDO: O aviso oficial de Level Up acontece aqui
	level_up.emit(level)
	
	var options = get_random_upgrades(3)
	get_tree().paused = true
	show_upgrade_options.emit(options)

func get_random_upgrades(amount: int) -> Array[UpgradeItem]:
	var pool = all_upgrades.duplicate()
	var selected: Array[UpgradeItem] = []
	pool.shuffle()
	var grab_count = min(amount, pool.size())
	for i in range(grab_count):
		selected.append(pool[i])
	return selected
