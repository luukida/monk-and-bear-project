extends Resource
class_name WaveData

@export var duration: float = 60.0 # Duração da onda em segundos
@export var spawn_interval: float = 1.0 # Tempo entre spawns (menor = mais inimigos)

# Lista de Inimigos Possíveis nesta onda
# Arraste as cenas (Grunt.tscn, Brute.tscn) para cá no Inspector
@export var possible_enemies: Array[PackedScene] = []
