extends Resource
class_name UpgradeItem

@export_group("Identidade")
@export var title: String = "Novo Upgrade"
@export_multiline var description: String = "Faz algo legal."
@export var icon: Texture2D # Arraste o sprite do ícone aqui

@export_group("Efeito")
## Quem recebe o upgrade?
@export var target: String = "bear" # Opções: "bear", "monk", "global"

## Qual variável vamos alterar no script do alvo? (ex: "damage", "move_speed")
@export var property_name: String = "damage"

## Quanto vamos somar? (ex: 10.0 para dano, 20.0 para speed)
@export var amount: float = 10.0

## Tipo de Upgrade (Para lógicas futuras como desbloquear habilidades)
@export var type: String = "stat_add" # "stat_add", "unlock", "special"
