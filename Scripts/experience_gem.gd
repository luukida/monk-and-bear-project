extends Area2D

@export var xp_value = 1

func _ready():
	# Conecta o sinal de quando algo entra na área
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Chama o Singleton Global
		GameManager.gain_xp(xp_value)
		
		# Opcional: Tocar som aqui
		
		queue_free() # Some com a gema
