extends AudioStreamPlayer

# You can drag different tracks here in the Inspector if you want
@export var menu_music: AudioStream
@export var battle_music: AudioStream

func _ready():
	# Allow playing even when the game is paused (e.g. in Settings)
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_menu_music():
	if stream != menu_music:
		stream = menu_music
		play()

func play_battle_music():
	if stream != battle_music:
		stream = battle_music
		play()

func stop_music():
	stop()
