extends Resource
class_name UpgradeItem

enum CardType { STAT, SKILL }

@export_group("Identidade")
@export var title: String = "Novo Upgrade"
@export_multiline var description: String = "Faz algo legal."
@export var icon: Texture2D 
@export var type: CardType = CardType.STAT # Default is Gray (Stat)

@export_group("Efeito")
@export var target: String = "bear" 
@export var property_name: String = "damage"
@export var amount: float = 10.0
