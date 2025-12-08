@tool
extends Path2D

@export_multiline var text: String = "Título do upgrade":
	set(value):
		text = value
		queue_update()

@export_group("Text Settings")
@export var orient_to_tangent: bool = true:
	set(value):
		orient_to_tangent = value
		queue_update()

@export var character_spacing: float = 0.0:
	set(value):
		character_spacing = value
		queue_update()

@export var start_offset: float = 0.0:
	set(value):
		start_offset = value
		queue_update()

@export var label_settings: LabelSettings:
	set(value):
		label_settings = value
		if label_settings and not label_settings.changed.is_connected(queue_update):
			label_settings.changed.connect(queue_update)
		queue_update()

@export_group("Tweaks")
# Positive moves 'i' forward, Negative moves it backward
@export var offset_i: float = 0.0:
	set(value):
		offset_i = value
		queue_update()

var _is_dirty = false

func _ready():
	if curve:
		curve.changed.connect(queue_update)
	queue_update()

func queue_update():
	_is_dirty = true
	if is_inside_tree():
		await get_tree().process_frame
		if _is_dirty:
			update_text_placement()
			_is_dirty = false

func update_text_placement():
	for child in get_children():
		if child is PathFollow2D:
			child.queue_free()
			
	if text.is_empty() or not curve: return
	
	var path_length = curve.get_baked_length()
	
	# 2. Get Font Data
	var font = null
	var f_size = 16
	if label_settings and label_settings.font:
		font = label_settings.font
		f_size = label_settings.font_size
	else:
		var lbl = Label.new()
		font = lbl.get_theme_default_font()
		f_size = lbl.get_theme_default_font_size()
		lbl.free()
	
	# 3. Calculate total width
	var total_text_pixel_width = 0.0
	for char_str in text:
		var char_w = font.get_string_size(char_str, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size).x
		total_text_pixel_width += char_w + character_spacing

	if text.length() > 0:
		total_text_pixel_width -= character_spacing
	
	# Start position
	var current_offset = (path_length / 2.0) - (total_text_pixel_width / 2.0) + start_offset
	
	# 4. Spawn letters
	for char_str in text:
		var char_w = font.get_string_size(char_str, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size).x
		
		# Base visual center
		var center_char_offset = current_offset + (char_w / 2.0)
		
		# --- MANUAL FIX FOR 'i' ---
		# Checks for "i", "I", and accented "í"
		if char_str in ["i", "I", "í", "ì"]:
			center_char_offset += offset_i
		
		var follower = PathFollow2D.new()
		follower.loop = false
		follower.rotates = orient_to_tangent
		follower.progress = center_char_offset
		add_child(follower)
		
		var label = Label.new()
		label.text = char_str
		label.label_settings = label_settings
		
		# Force center alignment on the point
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		label.grow_vertical = Control.GROW_DIRECTION_BOTH
		label.position = Vector2.ZERO 
		label.rotation_degrees = 0 
		
		follower.add_child(label)
		
		# Move to next character (based on original width, not tweaked position)
		current_offset += char_w + character_spacing
