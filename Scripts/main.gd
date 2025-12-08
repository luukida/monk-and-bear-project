extends Node2D

var settings_scene = preload("res://Scenes/settings_menu.tscn")

func _ready():
	# Garante que as referências existam antes de conectar
	if has_node("Monk") and has_node("Bear"):
		var monk = $Monk
		var bear = $Bear
		
		# Faz a conexão vital: Monge conhece Urso, Urso conhece Monge.
		monk.bear_node = bear
		bear.monk_node = monk
		
	# Check if MusicManager exists (Autoload) before calling
	if get_tree().root.has_node("MusicManager"):
		MusicManager.play_battle_music()

# Função chamada pelo WaveManager
func spawn_enemy(enemy_scene: PackedScene):
	if not has_node("Monk"): return
	
	var player_pos = $Monk.global_position
	var spawn_pos = Vector2.ZERO
	var valid_position_found = false
	
	# --- TRY TO FIND A VALID SPOT (Max 10 attempts) ---
	for i in range(10):
		var random_angle = randf() * TAU
		var distance = 600.0
		# Proposed position
		var test_pos = player_pos + Vector2(cos(random_angle), sin(random_angle)) * distance
		
		# Check if this position is inside a wall/sea
		if is_valid_spawn_pos(test_pos):
			spawn_pos = test_pos
			valid_position_found = true
			break # Found a good spot! Stop looking.
	
	# Only spawn if we found a valid spot
	if valid_position_found:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_pos
		add_child(enemy)
	else:
		print("DEBUG: Could not find valid spawn position after 10 tries.")

# Helper to check collision with World Layer
func is_valid_spawn_pos(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	
	# Check collision with Layer 6 (World)
	# Value 32 comes from 2^(6-1) = 2^5 = 32
	query.collision_mask = 32 
	
	# We also want to check against Areas if your water uses Area2D instead of StaticBody
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_point(query)
	
	# If result is empty, it means NO collision -> Valid spot
	return result.is_empty()

# Esta função será chamada pela UI quando o jogador clicar num botão
func apply_upgrade(upgrade: UpgradeItem):
	var target_node = null
	
	match upgrade.target:
		"bear": target_node = $Bear
		"monk": target_node = $Monk
	
	if target_node:
		# LOGIC FOR STATS (Numbers)
		if upgrade.type == UpgradeItem.CardType.STAT:
			if upgrade.property_name in target_node:
				var old_val = target_node.get(upgrade.property_name)
				target_node.set(upgrade.property_name, old_val + upgrade.amount)
				print("Stat Upgraded: ", upgrade.title)

		# LOGIC FOR SKILLS (Booleans)
		elif upgrade.type == UpgradeItem.CardType.SKILL: 
			if upgrade.property_name == "unlock_lunge":
				# Safety Check: Does 'can_lunge' exist on this bear?
				if "can_lunge" in target_node:
					target_node.can_lunge = true
					print("Skill Unlocked: Lunge")
					
			elif upgrade.property_name == "unlock_charge":
				if "can_charge" in target_node:
					target_node.can_charge = true
					print("Skill Unlocked: Charge")
					
			elif upgrade.property_name == "unlock_meteor":
				if "can_meteor" in target_node:
					target_node.can_meteor = true
					print("Skill Unlocked: Meteor Slam")
	
	get_tree().paused = false

func _input(event):
	# "ui_cancel" is mapped to ESC by default in Godot
	if event.is_action_pressed("ui_cancel"):
		toggle_settings()

func toggle_settings():
	# If we are already paused, assume we want to close (or handled by the menu itself)
	# But checking if the menu exists avoids duplicates
	if get_tree().paused:
		return 

	print("Opening Settings Popup...")
	
	# 1. Instantiate the Settings
	var settings = settings_scene.instantiate()
	
	# 2. Configure it as a Popup
	settings.is_gameplay_popup = true
	
	# 3. Create a temporary CanvasLayer 
	# (This ensures the menu draws ON TOP of your HUD and everything else)
	var layer = CanvasLayer.new()
	layer.layer = 100 # Very high priority
	layer.add_child(settings)
	add_child(layer)
	
	# 4. Pause the Game
	get_tree().paused = true
