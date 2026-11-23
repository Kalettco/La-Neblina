@tool
extends StaticBody2D
## Puerta de arena: raíces negras de la Bruma.
## - Entrada (cerrada_al_inicio = false): abierta; se cierra detrás de Lía al empezar la arena.
## - Salida  (cerrada_al_inicio = true): cerrada hasta vencer la última oleada.
## Al vencer la arena, todas las puertas de ese id se abren.
## Mide 1 casilla de ancho y "alto_casillas" de alto.
## Capa 4 (como las plataformas): bloquea a Lía pero deja pasar las chispas, para
## poder dispararle al farol de la entrada y recargar luz durante la pelea.
## Origen = esquina SUPERIOR IZQUIERDA de la casilla de arriba.

const CASILLA: float = 48.0
const TIEMPO_CAMBIO: float = 0.4
const COLOR_RAIZ: Color = Color(0.16, 0.08, 0.2)
const COLOR_VENA: Color = Color(0.55, 0.2, 0.7)
const ALFA_ABIERTA: float = 0.12

@export var id_arena: String = "arena"
@export var cerrada_al_inicio: bool = false
@export_range(1, 30) var alto_casillas: int = 3:
	set(valor):
		alto_casillas = valor
		if is_node_ready():
			_construir()

var cerrada: bool = false


func _ready() -> void:
	_construir()
	if Engine.is_editor_hint():
		return
	add_to_group("puertas_arena")
	reiniciar()


## Vuelve al estado inicial (cuando Lía muere dentro de la arena).
func reiniciar() -> void:
	_poner(cerrada_al_inicio, false)


func cerrar() -> void:
	_poner(true, true)


func abrir() -> void:
	_poner(false, true)


func _poner(cerrar_ahora: bool, animado: bool) -> void:
	cerrada = cerrar_ahora
	$CollisionShape2D.set_deferred("disabled", not cerrar_ahora)
	var alfa: float = 1.0 if cerrar_ahora else ALFA_ABIERTA
	var visual: Node2D = $Visual
	if animado:
		create_tween().tween_property(visual, "modulate:a", alfa, TIEMPO_CAMBIO)
		Audio.sfx_puerta()
	else:
		visual.modulate.a = alfa


## Colisión y marcador (raíces negras con venas moradas que brillan).
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
	var fondo: ColorRect = ColorRect.new()
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.color = COLOR_RAIZ
	fondo.size = Vector2(CASILLA, alto)
	visual.add_child(fondo)
	for i in range(2):
		var vena: Line2D = Line2D.new()
		vena.width = 3.0
		vena.default_color = COLOR_VENA
		if not Engine.is_editor_hint():
			vena.material = Efectos.material_sin_sombra()
		var y: float = 0.0
		while y <= alto:
			vena.add_point(Vector2(16.0 + i * 16.0 + sin(y * 0.07 + i * 3.0) * 7.0, y))
			y += 12.0
		visual.add_child(vena)
