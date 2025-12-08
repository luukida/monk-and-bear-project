extends "res://Scripts/base_enemy.gd"

@export_group("Spider Stats")
@export var web_cooldown: float = 3.0 # Cooldown variable (as requested)
@export var roam_radius: float = 300.0 
@export var web_scene: PackedScene = preload("res://Scenes/Enemies/spider_web.tscn")

# NEW: How many webs to drop at once
@export var min_webs: int = 1
@export var max_webs: int = 3

var current_web_timer: float = 0.0
var move_target: Vector2 = Vector2.ZERO
var move_timer: float = 0.0

func _ready():
	super._ready()
	pick_new_roam_target()
	
	current_web_timer = randf_range(0.1, 1.0)

func select_target() -> Node2D:
	if is_instance_valid(player_ref):
		return player_ref
	return null

func behavior_chase():
	var delta = get_process_delta_time()
	current_web_timer -= delta
	move_timer -= delta
	
	if not is_instance_valid(target):
		sprite.play("idle")
		return

	# 1. MOVEMENT (Random Roaming)
	if move_timer <= 0 or global_position.distance_to(move_target) < 10.0:
		pick_new_roam_target()
	
	var dir = global_position.direction_to(move_target)
	velocity = dir * speed
	sprite.play("run")
	update_orientation(move_target)
	
	# 2. WEB SPAWNING (Multi-Drop)
	if current_web_timer <= 0:
		spawn_webs_cluster()
		current_web_timer = web_cooldown

func pick_new_roam_target():
	if not is_instance_valid(target): return
	var random_angle = randf() * TAU
	var random_dist = randf_range(100.0, roam_radius)
	move_target = target.global_position + (Vector2.RIGHT.rotated(random_angle) * random_dist)
	move_timer = randf_range(2.0, 4.0)

func spawn_webs_cluster():
	if not web_scene: return
	
	# Randomize count (1 to 3)
	var count = randi_range(min_webs, max_webs)
	
	for i in range(count):
		var web = web_scene.instantiate()
		web.global_position = global_position
		get_tree().current_scene.add_child(web)
