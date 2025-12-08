extends CanvasLayer

# UI References
@onready var xp_bar = $XPBar
@onready var level_label = $XPBar/LevelLabel

@onready var monk_hp_bar = $MonkPanel/HPBar
# Assuming Monk slots are also generic now, or keep specific if Monk skills are fixed
@onready var monk_slots_container = $MonkPanel/Skills

@onready var bear_hp_bar = $BearPanel/HPBar
@onready var bear_slots_container = $BearPanel/Skills
@onready var rope_bar = $RopeBar

# Icons (Drag these in Inspector)
@export var icon_lunge: Texture2D
@export var icon_charge: Texture2D
@export var icon_meteor: Texture2D
@export var icon_honey: Texture2D

# Internal
var monk_ref = null
var bear_ref = null
var rope_ref = null

# Track assigned skills to avoid re-setting them every frame
var bear_active_skills = [] 

func _ready():
	GameManager.xp_changed.connect(update_xp)
	GameManager.level_up.connect(update_level)
	
	update_xp(GameManager.current_xp, GameManager.required_xp)
	update_level(GameManager.level)
	
	await get_tree().process_frame
	find_game_objects()
	
	# Clear all slots initially (or set them to empty state)
	clear_slots(bear_slots_container)
	
	# Initialize Monk (Assuming Honey is always Slot 1 for now)
	# If Monk also needs dynamic slots, apply the same logic as Bear below
	var honey_slot = monk_slots_container.get_child(0)
	if honey_slot and icon_honey:
		honey_slot.setup(icon_honey, "1")

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
		# Honey Logic (Fixed Slot 1)
		var honey_slot = monk_slots_container.get_child(0)
		if honey_slot:
			honey_slot.update_cooldown(monk_ref.honey_current_cooldown, monk_ref.honey_cooldown_time)
			honey_slot.set_active_state(monk_ref.is_aiming_skill_1)

	# 2. BEAR (Dynamic Slots)
	if bear_ref:
		bear_hp_bar.value = bear_ref.current_hp
		update_bear_slots()

	# 3. ROPE
	if rope_ref:
		rope_bar.value = rope_ref.current_durability

func update_bear_slots():
	# Define the list of potential skills in priority order
	# Format: [Check Variable, Icon, Cooldown Current, Cooldown Max, Active State]
	var skills_data = []
	
	# Skill 1: Lunge
	if bear_ref.can_lunge:
		var is_lunging = (bear_ref.current_state == bear_ref.State.ATTACK)
		skills_data.append({
			"icon": icon_lunge,
			"cd_current": 0.0,
			"cd_max": 0.0,
			"active": is_lunging
		})
		
	# Skill 2: Charge
	if bear_ref.can_charge:
		var is_charging = (bear_ref.current_state == bear_ref.State.CHARGE_PREP or bear_ref.current_state == bear_ref.State.CHARGING)
		skills_data.append({
			"icon": icon_charge,
			"cd_current": bear_ref.current_charge_cooldown,
			"cd_max": bear_ref.charge_cooldown,
			"active": is_charging
		})
		
	# Skill 3: Meteor
	if bear_ref.can_meteor:
		var is_jumping = (bear_ref.current_state == bear_ref.State.METEOR_JUMP)
		skills_data.append({
			"icon": icon_meteor,
			"cd_current": bear_ref.current_meteor_cooldown,
			"cd_max": bear_ref.meteor_cooldown,
			"active": is_jumping
		})
	
	# Loop through UI Slots and assign data
	var slots = bear_slots_container.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		
		if i < skills_data.size():
			# This slot has a skill!
			var data = skills_data[i]
			
			# Setup (Only if changed, to avoid flickering)
			# You might need to expose a getter for the current texture in skill_slot.gd
			if slot.icon_rect.texture != data.icon:
				slot.setup(data.icon, "")
				slot.visible = true # Ensure it's visible
			
			# Update Frame
			slot.update_cooldown(data.cd_current, data.cd_max)
			slot.set_active_state(data.active)
			slot.modulate.a = 1.0 # Fully visible
			
		else:
			# Empty Slot
			# Option A: Hide it? 
			# slot.visible = false 
			
			# Option B: Show Empty Placeholder?
			slot.setup(null, "") # Clear icon
			slot.modulate.a = 0.5 # Dim it
			slot.update_cooldown(0, 0)
			slot.set_active_state(false)

func clear_slots(container):
	for slot in container.get_children():
		slot.setup(null, "")
		slot.modulate.a = 0.5

# ... (Update XP/Level callbacks) ...
func update_xp(current, required):
	xp_bar.max_value = required
	xp_bar.value = current

func update_level(new_level):
	level_label.text = str(new_level)
