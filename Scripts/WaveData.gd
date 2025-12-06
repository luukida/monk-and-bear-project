extends Resource
class_name WaveData

@export var duration: float = 60.0
@export var spawn_interval: float = 1.0
@export var wave_message: String = ""

# Now we use an Array of the separate file we just created
@export var enemies: Array[SpawnInfo] = []
