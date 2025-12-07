extends Node

const XP_BASE = 5
const XP_FACTOR = 1.2

var level = 1
var current_xp = 0
var required_xp = 0

# To track what wave we died on
var survived_wave_number: int = 1

# SEPARATE POOLS
@export var stat_upgrades: Array[UpgradeItem] = []
@export var skill_upgrades: Array[UpgradeItem] = []

# Chance for a card slot to become a Skill Card (e.g., 20%)
@export var skill_card_chance: float = 1.0

signal xp_changed(current, required)
signal level_up(new_level)
signal show_upgrade_options(options) 
signal game_over(wave) # Signal to open the UI

func _ready():
	await get_tree().create_timer(0.1).timeout
	reset_progress() # Ensure we start fresh

func calculate_required_xp():
	required_xp = round(XP_BASE * pow(XP_FACTOR, level))
	xp_changed.emit(current_xp, required_xp)

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
	level_up.emit(level)
	
	var options = get_random_upgrades(3)
	get_tree().paused = true
	show_upgrade_options.emit(options)

func get_random_upgrades(amount: int) -> Array[UpgradeItem]:
	var selected: Array[UpgradeItem] = []
	
	# Create temporary shuffled copies
	var available_stats = stat_upgrades.duplicate()
	var available_skills = skill_upgrades.duplicate()
	available_stats.shuffle()
	available_skills.shuffle()
	
	for i in range(amount):
		# ROLL THE DICE: Skill or Stat?
		var pick_skill = false
		
		# Condition: We must have skills to pick AND pass the RNG check
		if available_skills.size() > 0 and randf() <= skill_card_chance:
			pick_skill = true
		
		# Fallback: If we wanted a stat but ran out, pick skill
		if available_stats.size() == 0 and available_skills.size() > 0:
			pick_skill = true
			
		# SELECT THE CARD
		if pick_skill:
			selected.append(available_skills.pop_front())
		else:
			if available_stats.size() > 0:
				selected.append(available_stats.pop_front())
			
	return selected

# --- GAME OVER LOGIC ---

func trigger_game_over(wave_idx: int):
	survived_wave_number = wave_idx
	get_tree().paused = true # Stop everything!
	game_over.emit(survived_wave_number)

func reset_progress():
	# Reset stats for a new run
	level = 1
	current_xp = 0
	calculate_required_xp()
	# Note: Since upgrades are applied directly to Nodes (Monk/Bear) 
	# and the Scene reloads, we don't need to manually clear them here. 
	# The new scene will start fresh.

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		if not event.echo: 
			print("CHEAT: Instant Level Up!")
			# Calculate exactly how much XP is needed to reach the next level
			var xp_to_next_level = required_xp - current_xp
			gain_xp(xp_to_next_level)
