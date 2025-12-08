extends CanvasLayer

# UI References
@onready var xp_bar = $XPBar
@onready var level_label = $XPBar/LevelLabel

@onready var monk_hp_bar = $MonkPanel/HPBar
@onready var monk_slots_container = $MonkPanel/Skills 

@onready var bear_hp_bar = $BearPanel/HPBar
@onready var bear_slots_container = $BearPanel/Skills
@onready var rope_bar = $RopeBar

# --- ICONS ---
# Drag these in the Inspector!
@export var icon_lunge: Texture2D
@export var icon_charge: Texture2D
@export var icon_meteor: Texture2D
@export var icon_honey: Texture2D # NEW

var monk_ref = null
var bear_ref = null
var rope_ref = null

func _ready():
	GameManager.xp_changed.connect(update_xp)
	GameManager.level_up.connect(update_level)
	
	update_xp(GameManager.current_xp, GameManager.required_xp)
	update_level(GameManager.level)
	
	await get_tree().process_frame
	find_game_objects()
	
	# Clear all slots initially so they appear empty
	clear_slots(monk_slots_container)
	clear_slots(bear_slots_container)

func find_game_objects():
	monk_ref = get_tree().get_first_node_in_group("player")
	bear_ref = get_tree().get_first_node_in_group("bear")
	
	var ropes = get_tree().get_nodes_in_group("rope_controller") 
	if ropes.size() > 0:
		rope_ref = ropes[0]
	
	if monk_ref: monk_hp_bar.max_value = monk_ref.max_hp
	if bear_ref: bear_hp_bar.max_value = bear_ref.max_hp
	if rope_ref: rope_bar.max_value = rope_ref.max_durability

func _process(delta):
	# 1. MONK
	if monk_ref:
		monk_hp_bar.value = monk_ref.current_hp
		update_monk_slots() # Now uses the dynamic array

	# 2. BEAR
	if bear_ref:
		bear_hp_bar.value = bear_ref.current_hp
		update_bear_slots()

	# 3. ROPE
	if rope_ref:
		rope_bar.value = rope_ref.current_durability

func update_monk_slots():
	var skills_data = []
	
	# Loop through the ordered list of unlocked skills
	# Ensure active_skills exists on Monk before accessing!
	if "active_skills" in monk_ref:
		for skill_name in monk_ref.active_skills:
			if skill_name == "honey_pot":
				skills_data.append({
					"icon": icon_honey,
					"cd_current": monk_ref.honey_current_cooldown,
					"cd_max": monk_ref.honey_cooldown_time,
					"active": monk_ref.is_aiming_skill_1
				})
			# Add other skills here later...
	
	# CALL 1: Pass 'true' to show hotkeys
	apply_data_to_slots(monk_slots_container, skills_data, true)

func update_bear_slots():
	var skills_data = []
	
	if bear_ref.can_lunge:
		var is_lunging = (bear_ref.current_state == bear_ref.State.ATTACK)
		skills_data.append({
			"icon": icon_lunge,
			"cd_current": 0.0,
			"cd_max": 0.0,
			"active": is_lunging
		})
		
	if bear_ref.can_charge:
		var is_charging = (bear_ref.current_state == bear_ref.State.CHARGE_PREP or bear_ref.current_state == bear_ref.State.CHARGING)
		skills_data.append({
			"icon": icon_charge,
			"cd_current": bear_ref.current_charge_cooldown,
			"cd_max": bear_ref.charge_cooldown,
			"active": is_charging
		})
		
	if bear_ref.can_meteor:
		var is_jumping = (bear_ref.current_state == bear_ref.State.METEOR_JUMP)
		skills_data.append({
			"icon": icon_meteor,
			"cd_current": bear_ref.current_meteor_cooldown,
			"cd_max": bear_ref.meteor_cooldown,
			"active": is_jumping
		})
	
	# CALL 2: Pass 'false' to hide hotkeys (THIS WAS MISSING!)
	apply_data_to_slots(bear_slots_container, skills_data, false)

# HELPER DEFINITION: Accepts 3 arguments
func apply_data_to_slots(container, data_list, show_keys: bool):
	var slots = container.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		
		# Dynamic Hotkey: "1", "2", "3" based on slot index
		var key_text = ""
		if show_keys:
			key_text = str(i + 1)
		
		if i < data_list.size():
			# FILLED SLOT
			var data = data_list[i]
			
			if slot.icon_rect.texture != data.icon:
				slot.setup(data.icon, key_text) 
				
			slot.update_cooldown(data.cd_current, data.cd_max)
			slot.set_active_state(data.active)
			slot.modulate.a = 1.0 
			
		else:
			# EMPTY SLOT
			if slot.icon_rect.texture != null:
				slot.setup(null, key_text) # Show "1", "2" even if empty
			
			slot.modulate.a = 0.3 
			slot.update_cooldown(0, 0)
			slot.set_active_state(false)

func clear_slots(container):
	for slot in container.get_children():
		slot.setup(null, "")
		slot.modulate.a = 0.3

func update_xp(current, required):
	xp_bar.max_value = required
	xp_bar.value = current

func update_level(new_level):
	level_label.text = str(new_level)
