@tool
extends Area2D
## Cartel de madera o Nota de papá.
## El texto lo muestra el HUD cuando Lía está cerca (lo decide el autoload Juego).
## Origen = centro inferior de la casilla (pie del poste).

const COLOR_TABLA: Color = Color(0.45, 0.3, 0.17)
const COLOR_PAPEL: Color = Color(0.9, 0.86, 0.74)

@export_multiline var texto: String = ""
@export var es_nota: bool = false:
	set(valor):
		es_nota = valor
		if is_node_ready():
			_aplicar_aspecto()


func _ready() -> void:
	_aplicar_aspecto()
	if not Engine.is_editor_hint():
		add_to_group("carteles")


func _aplicar_aspecto() -> void:
	var tabla: ColorRect = $Visual/Tabla
	tabla.color = COLOR_PAPEL if es_nota else COLOR_TABLA
	# La nota de papá va clavada un poco inclinada
	tabla.rotation = deg_to_rad(-8.0) if es_nota else 0.0
