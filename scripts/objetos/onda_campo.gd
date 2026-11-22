extends Node2D
## Onda expansiva del campo de luz: un anillo que crece desde Lía
## hasta radio_final en 0,3 s y luego se desvanece.

const TIEMPO_EXPANSION: float = 0.3
const TIEMPO_DESVANECER: float = 0.4
const COLOR_ANILLO: Color = Color(1.0, 0.93, 0.65)

var radio_final: float = 1100.0
var _tiempo: float = 0.0


func _ready() -> void:
	material = Efectos.material_sin_sombra()
	z_index = 5


func _process(delta: float) -> void:
	_tiempo += delta
	if _tiempo >= TIEMPO_EXPANSION + TIEMPO_DESVANECER:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var avance: float = minf(_tiempo / TIEMPO_EXPANSION, 1.0)
	var radio: float = radio_final * ease(avance, 0.4)
	var alfa: float = 1.0
	if _tiempo > TIEMPO_EXPANSION:
		alfa = 1.0 - (_tiempo - TIEMPO_EXPANSION) / TIEMPO_DESVANECER
	# Relleno muy suave y anillo brillante
	draw_circle(Vector2.ZERO, radio, Color(COLOR_ANILLO, 0.08 * alfa))
	draw_arc(Vector2.ZERO, radio, 0.0, TAU, 96, Color(COLOR_ANILLO, 0.85 * alfa), 10.0)
	draw_arc(Vector2.ZERO, radio * 0.97, 0.0, TAU, 96, Color(COLOR_ANILLO, 0.35 * alfa), 24.0)
