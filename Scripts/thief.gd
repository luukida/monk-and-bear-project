extends "res://Scripts/base_enemy.gd"

@export_group("Stalker Behavior")
@export var flee_speed: float = 300.0 
@export var bear_detection_range: float = 350.0 
@export var bear_safe_distance: float = 500.0
@export var stalk_duration: float = 2.0 
@export var bravery_chance: float = 0.25 

@export_group("Audio")
@export var vanish_sound: AudioStream

@onready var vanish_player = $VanishPlayer 

var is_fleeing = false
var is_stalking = false
var is_brave = false 
var stalk_timer = 0.0

func _ready():
	super._ready()
	# FIX: Apply alpha to SPRITE only, not the whole node
	sprite.modulate.a = 0.4 

func select_target() -> Node2D:
	if is_instance_valid(player_ref):
		return player_ref
	return null

func behavior_chase():
	var delta = get_process_delta_time()
	
	if is_brave:
		sprite.speed_scale = 1.0
		super.behavior_chase()
		return

	# --- FEAR LOGIC ---
	var dist_to_bear = INF
	if is_instance_valid(bear_ref) and not bear_ref.get("is_downed"):
		dist_to_bear = global_position.distance_to(bear_ref.global_position)
	
	if dist_to_bear < bear_detection_range and not is_fleeing and not is_stalking:
		if randf() < bravery_chance:
			is_brave = true
			# FIX: Update Sprite only
			sprite.modulate = Color(1, 1, 1, 0.4) 
			return 
		else:
			is_fleeing = true
			set_collision_mask_value(3, false) # Ghost Mode

	# --- FLEEING ---
	if is_fleeing:
		if dist_to_bear > bear_safe_distance:
			is_fleeing = false
			set_collision_mask_value(3, true) # Solid Mode
			is_stalking = true
			stalk_timer = stalk_duration
			sprite.speed_scale = 1.0 
			return 
			
		var flee_dir = (global_position - bear_ref.global_position).normalized()
		velocity = flee_dir * flee_speed
		sprite.play("run")
		sprite.speed_scale = 2.5 
		update_orientation(global_position + flee_dir)
		return

	# --- STALKING ---
	if is_stalking:
		if dist_to_bear < (bear_detection_range * 0.5): 
			is_stalking = false
			return 

		stalk_timer -= delta
		velocity = Vector2.ZERO 
		sprite.play("idle")
		sprite.speed_scale = 1.0
		
		if is_instance_valid(player_ref):
			update_orientation(player_ref.global_position) 
			
		if stalk_timer <= 0:
			is_stalking = false
		return 

	sprite.speed_scale = 1.0 
	super.behavior_chase()

# --- COMBAT VISIBILITY ---

func start_attack():
	# FIX: Sprite becomes visible, Marker remains visible (it was never hidden)
	sprite.modulate = Color.WHITE 
	super.start_attack()

func _on_animation_finished():
	super._on_animation_finished() 
	
	if sprite.animation == "attack":
		is_brave = false
		
		if vanish_player and vanish_sound:
			vanish_player.stream = vanish_sound
			vanish_player.pitch_scale = randf_range(0.9, 1.1)
			vanish_player.play()
		
		# FIX: Tween Sprite Only
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.4), 0.3)

# --- DAMAGE OVERRIDE ---
# We override this to ensure he goes back to Transparency after flashing Red
func take_damage(amount):
	hp -= amount
	
	# Flash Red
	sprite.modulate = Color.RED
	var tween = create_tween()
	
	# FIX: Return to Transparent (0.4) instead of White (1.0)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.4), 0.1)
	
	# Audio (Reusing base variables)
	if hp > 0 and hit_player and not hit_sounds.is_empty():
		hit_player.stream = hit_sounds.pick_random()
		hit_player.pitch_scale = randf_range(0.9, 1.1)
		hit_player.play()
	
	if hp <= 0:
		play_death_sound_detached()
		spawn_gem()
		queue_free()
