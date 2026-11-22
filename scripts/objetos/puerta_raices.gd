@tool
extends StaticBody2D
## Puerta de raíces: bloquea el paso hasta que un brasero de su grupo se enciende.
## Mide 1 casilla de ancho y "alto_casillas" de alto.
## Origen = esquina SUPERIOR IZQUIERDA de la casilla de arriba.

const CASILLA: float = 48.0
const TIEMPO_ABRIR: float = 0.67
const COLOR_MADERA: Color = Color(0.36, 0.23, 0.13)
const COLOR_RAIZ: Color = Color(0.22, 0.13, 0.07)

@export var grupo: String = "a"
@export_range(1, 30) var alto_casillas: int = 3:
	set(valor):
		alto_casillas = valor
		if is_node_ready():
			_construir()

var abierta: bool = false


func _ready() -> void:
	_construir()
	if not Engine.is_editor_hint():
		add_to_group("puertas")


func abrir() -> void:
	if abierta:
		return
	abierta = true
	$CollisionShape2D.set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.tween_property($Visual, "modulate:a", 0.0, TIEMPO_ABRIR)


## Crea la colisión y el marcador (madera con líneas de raíz) según el alto.
func _construir() -> void:
	var alto: float = alto_casillas * CASILLA
	var forma: RectangleShape2D = RectangleShape2D.new()
	forma.size = Vector2(CASILLA, alto)
	var colision: CollisionShape2D = $CollisionShape2D
	colision.shape = forma
	colision.position = Vector2(CASILLA / 2.0, alto / 2.0)

	var visual: Node2D = $Visual
	for hijo: Node in visual.get_children():
		hijo.queue_free()
	var madera: ColorRect = ColorRect.new()
	madera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	madera.color = COLOR_MADERA
	madera.size = Vector2(CASILLA, alto)
	visual.add_child(madera)
	# Líneas de raíz que serpentean de arriba abajo
	for i in range(3):
		var raiz: Line2D = Line2D.new()
		raiz.width = 5.0
		raiz.default_color = COLOR_RAIZ
		var x_base: float = 10.0 + i * 14.0
		var y: float = 0.0
		while y <= alto:
			raiz.add_point(Vector2(x_base + sin(y * 0.05 + i * 2.0) * 5.0, y))
			y += 12.0
		visual.add_child(raiz)
