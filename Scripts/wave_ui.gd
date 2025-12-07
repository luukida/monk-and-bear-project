extends CanvasLayer

@export var wave_start_sound: AudioStream # Drag your sound here!

@onready var timer_label = $Container/TimerLabel
@onready var announcement_label = $Container/AnnouncementLabel
@onready var wave_sfx = $WaveSFX

func _ready():
	await get_tree().process_frame
	
	# Começa invisível
	timer_label.modulate.a = 0.0
	
	var wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")
	
	if wave_manager:
		wave_manager.time_updated.connect(_on_time_updated)
		wave_manager.wave_changed.connect(_on_wave_changed)
	else:
		print("ERROR: WaveUI could not find 'WaveManager' in the scene!")

func _on_time_updated(time_text: String):
	timer_label.text = time_text

func _on_wave_changed(wave_index: int, wave_name: String):
	announcement_label.text = wave_name
	
	# Reseta transparência (Texto some, Timer some)
	announcement_label.modulate.a = 0.0
	timer_label.modulate.a = 0.0
	
	# --- PLAY SOUND WITH FADE OUT ---
	if wave_sfx and wave_start_sound:
		wave_sfx.stream = wave_start_sound
		wave_sfx.volume_db = 0.0 # Reset volume to max
		wave_sfx.play()
		
		var audio_len = wave_start_sound.get_length()
		var fade_duration = 1.5 
		
		var audio_tween = create_tween()
		
		# If sound is long enough, wait then fade
		if audio_len > fade_duration:
			audio_tween.tween_interval(audio_len - fade_duration)
			# CHANGED: Use TRANS_LINEAR for a consistent volume drop you can actually hear
			audio_tween.tween_property(wave_sfx, "volume_db", -80.0, fade_duration).set_trans(Tween.TRANS_LINEAR)
		else:
			# If sound is short (e.g. 1.0s), fade it over its entire duration so it's smooth
			audio_tween.tween_property(wave_sfx, "volume_db", -80.0, audio_len).set_trans(Tween.TRANS_LINEAR)
	
	# --- SEQUÊNCIA DE ANIMAÇÃO ---
	var tween = create_tween()
	
	# 1. Texto Aparece (0.5s)
	tween.tween_property(announcement_label, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 2. Texto Fica na tela (2.0s) -> O timing que você gostou
	tween.tween_interval(2.0) 
	
	# 3. Texto Some (1.0s)
	tween.tween_property(announcement_label, "modulate:a", 0.0, 1.0)
	
	# 4. Timer Aparece (0.5s) -> Só acontece depois que o texto sumiu completamente
	tween.tween_property(timer_label, "modulate:a", 1.0, 0.5)
