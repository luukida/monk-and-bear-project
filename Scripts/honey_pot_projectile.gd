extends Node2D

var target_pos: Vector2
# PRELOAD DA POÇA QUE ACABAMOS DE CRIAR
var puddle_scene = preload("res://Scenes/Skills/honey_pot.tscn") 

func launch(start_pos, end_pos):
	global_position = start_pos
	target_pos = end_pos
	
	# Animação de Arco (Movimento linear + Pulo no Y)
	var duration = 0.5
	
	# Tween de Posição (X e Y linear)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", end_pos, duration).set_ease(Tween.EASE_OUT)
	
	# Tween de "Arco" (Sobe e desce o sprite visualmente)
	var sprite = $Sprite2D
	var jump_height = 80.0
	var jump_tween = create_tween()
	# Sobe
	jump_tween.tween_property(sprite, "position:y", -jump_height, duration / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Desce
	jump_tween.tween_property(sprite, "position:y", 0.0, duration / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	await tween.finished
	smash()

func smash():
	# Instancia a poça no chão
	if puddle_scene:
		var puddle = puddle_scene.instantiate()
		puddle.global_position = global_position
		# Adiciona na raiz da cena para não se mover com o monge
		get_tree().current_scene.add_child(puddle)
	
	# Aqui você pode adicionar som de vidro quebrando
	queue_free()
