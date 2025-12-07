extends AudioStreamPlayer

@export var menu_music: AudioStream
@export var battle_music: AudioStream

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_menu_music():
	if stream != menu_music:
		stream = menu_music
		play()
	# FIX: If it's the right song but stopped, play it!
	elif not playing:
		play()

func play_battle_music():
	if stream != battle_music:
		stream = battle_music
		play()
	# FIX: If it's the right song but stopped, play it!
	elif not playing:
		play()

func stop_music():
	stop()
