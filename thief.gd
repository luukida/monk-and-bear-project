extends "res://Scripts/base_enemy.gd" # <--- Herda tudo do script original!

# Sobrescrevemos APENAS a função de escolher alvo.
# O resto (movimento, animação, dano) continua funcionando igual ao pai.
func select_target() -> Node2D:
	# O Thief é um assassino focado.
	# Ele IGNORA o urso (a menos que o urso tenha caído, aí ele vai no player de qualquer jeito).
	
	# Se o player morreu, não tem alvo
	if not is_instance_valid(player_ref):
		return null
		
	# Retorna SEMPRE o player, ignorando a distância do urso
	return player_ref
