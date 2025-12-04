extends "res://Scripts/base_enemy.gd"

var rope_ref: Area2D = null

func select_target() -> Node2D:
	# 1. Busca a corda se não tiver referência
	if not is_instance_valid(rope_ref):
		var ropes = get_tree().get_nodes_in_group("rope")
		if ropes.size() > 0:
			rope_ref = ropes[0]
	
	# 2. Validação Robusta
	if is_instance_valid(rope_ref):
		var rope_controller = rope_ref.get_parent()
		
		# Se o controlador diz que está quebrado, retorna NULL para fugir
		if rope_controller and rope_controller.get("is_broken"):
			return null
			
		# Se a corda existe e está inteira, ela é o alvo
		return rope_ref
		
	# 3. Não achou nada? Foge.
	return null

func behavior_chase():
	# Se não tem alvo (Corda quebrou), FOGE
	if target == null:
		flee_and_despawn()
		return
	
	if target == rope_ref:
		chase_rope_center()
	else:
		super.behavior_chase()

func chase_rope_center():
	var rope_controller = target.get_parent()
	
	if not is_instance_valid(rope_controller) or not is_instance_valid(rope_controller.player) or not is_instance_valid(rope_controller.bear):
		return

	var p1 = rope_controller.player.global_position
	var p2 = rope_controller.bear.global_position
	var target_pos = (p1 + p2) / 2.0
	
	if hitbox.overlaps_area(target):
		start_attack()
	else:
		var dir = global_position.direction_to(target_pos)
		velocity = dir * speed
		sprite.play("run")
		update_orientation(target_pos)

func flee_and_despawn():
	var flee_dir = Vector2.RIGHT
	
	# CORREÇÃO: Foge do URSO (centro da tela), não do Player
	if is_instance_valid(bear_ref):
		flee_dir = (global_position - bear_ref.global_position).normalized()
	
	# Foge rápido
	velocity = flee_dir * (speed * 1.5)
	sprite.play("run")
	update_orientation(global_position + flee_dir)
	
	# CORREÇÃO: Checa distância do URSO para despawnar
	if is_instance_valid(bear_ref):
		# 1000px garante que saiu bem da tela (que tem largura ~1280)
		if global_position.distance_to(bear_ref.global_position) > 1000:
			print("Snake fugiu com sucesso e foi deletada!")
			queue_free()

func apply_damage_snapshot():
	super.apply_damage_snapshot()
	
	var areas = hitbox.get_overlapping_areas()
	for area in areas:
		if area.is_in_group("rope"):
			var rope_ctrl = area.get_parent()
			if rope_ctrl.has_method("take_damage"):
				rope_ctrl.take_damage(damage)
