extends CanvasLayer

# UI References
@onready var xp_bar = $XPBar
@onready var level_label = $XPBar/LevelLabel

@onready var monk_hp_bar = $MonkPanel/HPBar
@onready var skill_honey = $MonkPanel/Skills/SlotHoney 

@onready var bear_hp_bar = $BearPanel/HPBar
@onready var rope_bar = $RopeBar

# --- BEAR SKILL SLOTS ---
@onready var slot_lunge = $BearPanel/SkillsBearContainer/SlotLunge
@onready var slot_charge = $BearPanel/SkillsBearContainer/SlotCharge
@onready var slot_meteor = $BearPanel/SkillsBearContainer/SlotMeteor

# Icons (Optional: Drag specific textures here in Inspector if you want)
@export var icon_lunge: Texture2D
@export var icon_charge: Texture2D
@export var icon_meteor: Texture2D

var monk_ref = null
var bear_ref = null
var rope_ref = null

func _ready():
	GameManager.xp_changed.connect(update_xp)
	GameManager.level_up.connect(update_level)
	
	update_xp(GameManager.current_xp, GameManager.required_xp)
	update_level(GameManager.level)
	
	# Setup Icons (You can also set them in the scene directly)
	# Passing "" hides the key label
	if icon_lunge: slot_lunge.setup(icon_lunge, "")
	else: slot_lunge.setup(slot_lunge.icon_rect.texture, "") # Use existing
		
	if icon_charge: slot_charge.setup(icon_charge, "")
	else: slot_charge.setup(slot_charge.icon_rect.texture, "")
		
	if icon_meteor: slot_meteor.setup(icon_meteor, "")
	else: slot_meteor.setup(slot_meteor.icon_rect.texture, "")
	
	await get_tree().process_frame
	find_game_objects()

func find_game_objects():
	monk_ref = get_tree().get_first_node_in_group("player")
	bear_ref = get_tree().get_first_node_in_group("bear")
	
	var ropes = get_tree().get_nodes_in_group("rope") 
	if ropes.size() > 0:
		# RopeHurtbox is in group 'rope', its parent is the controller
		rope_ref = ropes[0].get_parent() 
	
	if monk_ref: monk_hp_bar.max_value = monk_ref.max_hp
	if bear_ref: bear_hp_bar.max_value = bear_ref.max_hp
	if rope_ref: rope_bar.max_value = rope_ref.max_durability

func _process(delta):
	# 1. MONK
	if monk_ref:
		monk_hp_bar.value = monk_ref.current_hp
		skill_honey.update_cooldown(monk_ref.honey_current_cooldown, monk_ref.honey_cooldown_time)
		
		# Flash Honey slot while aiming
		skill_honey.set_active_state(monk_ref.is_aiming_skill_1)

	# 2. BEAR
	if bear_ref:
		bear_hp_bar.value = bear_ref.current_hp
		
		# --- SKILL 1: LUNGE ---
		# Lunge is active during ATTACK state if unlocked
		# Note: We check 'can_lunge' to gray it out if not learned yet
		var is_lunging = (bear_ref.current_state == bear_ref.State.ATTACK)
		slot_lunge.set_active_state(is_lunging)
		slot_lunge.modulate.a = 1.0 if bear_ref.can_lunge else 0.4
		
		# --- SKILL 2: CHARGE ---
		slot_charge.update_cooldown(bear_ref.current_charge_cooldown, bear_ref.charge_cooldown)
		
		var is_charging = (bear_ref.current_state == bear_ref.State.CHARGE_PREP or bear_ref.current_state == bear_ref.State.CHARGING)
		slot_charge.set_active_state(is_charging)
		slot_charge.modulate.a = 1.0 if bear_ref.can_charge else 0.4

		# --- SKILL 3: METEOR ---
		# (Only if you added the Meteor code to Bear)
		if "current_meteor_cooldown" in bear_ref:
			slot_meteor.update_cooldown(bear_ref.current_meteor_cooldown, bear_ref.meteor_cooldown)
			
			var is_jumping = (bear_ref.current_state == bear_ref.State.METEOR_JUMP)
			slot_meteor.set_active_state(is_jumping)
			slot_meteor.modulate.a = 1.0 if bear_ref.can_meteor else 0.4

	# 3. ROPE
	if rope_ref:
		rope_bar.value = rope_ref.current_durability

func update_xp(current, required):
	xp_bar.max_value = required
	xp_bar.value = current

func update_level(new_level):
	level_label.text = str(new_level)
