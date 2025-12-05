extends CanvasLayer

# Referências da UI
@onready var xp_bar = $XPBar
@onready var level_label = $XPBar/LevelLabel

@onready var monk_hp_bar = $MonkPanel/HPBar
@onready var skill_honey = $MonkPanel/Skills/SlotHoney # Instancie a cena skill_slot e nomeie assim

@onready var bear_hp_bar = $BearPanel/HPBar
@onready var rope_bar = $RopeBar

# Referências do Jogo (Serão buscadas no _ready ou via sinais)
var monk_ref = null
var bear_ref = null
var rope_ref = null

func _ready():
	# 1. Conecta GameManager (XP e Level)
	GameManager.xp_changed.connect(update_xp)
	GameManager.level_up.connect(update_level)
	
	# Inicializa valores do GameManager
	update_xp(GameManager.current_xp, GameManager.required_xp)
	update_level(GameManager.level)
	
	# 2. Busca referências na cena (Método seguro de espera)
	# Aguarda 1 frame para garantir que Monk/Bear estejam prontos
	await get_tree().process_frame
	find_game_objects()

func find_game_objects():
	monk_ref = get_tree().get_first_node_in_group("player")
	bear_ref = get_tree().get_first_node_in_group("bear")
	
	# A corda pode não estar num grupo, então buscamos via nó se precisar, 
	# ou adicionamos ela ao grupo "rope_controller" no editor.
	# Vamos assumir que você adicionou o RopeController ao grupo "rope_controller"
	var ropes = get_tree().get_nodes_in_group("rope_controller") 
	if ropes.size() > 0:
		rope_ref = ropes[0]
	
	# Configura Max Values iniciais
	if monk_ref: monk_hp_bar.max_value = monk_ref.max_hp
	if bear_ref: bear_hp_bar.max_value = bear_ref.max_hp
	if rope_ref: rope_bar.max_value = rope_ref.max_durability

func _process(delta):
	# Atualização constante (Vida e Cooldowns mudam a todo frame)
	if monk_ref:
		monk_hp_bar.value = monk_ref.current_hp
		# Atualiza o slot da skill (passando tempo atual e total)
		skill_honey.update_cooldown(monk_ref.honey_current_cooldown, monk_ref.honey_cooldown_time)
		
	if bear_ref:
		bear_hp_bar.value = bear_ref.current_hp
		
	if rope_ref:
		rope_bar.value = rope_ref.current_durability

# Callbacks do GameManager
func update_xp(current, required):
	xp_bar.max_value = required
	xp_bar.value = current

func update_level(new_level):
	level_label.text = str(new_level)
