@tool
extends Area2D
## Peligro: agua helada o espinas. Tocarlo = muerte.
## Ocupa una fila de "ancho_casillas" casillas.
## Origen = esquina SUPERIOR IZQUIERDA de la primera casilla.

const CASILLA: float = 48.0
const COLOR_AGUA: Color = Color(0.05, 0.12, 0.26)
const COLOR_OLEAJE: Color = Color(0.45, 0.7, 0.9, 0.7)
const COLOR_ESPINAS: Color = Color(0.28, 0.13, 0.32)

@export_enum("agua", "espinas") var tipo: String = "agua":
	set(valor):
		tipo = valor
		if is_node_ready():
			_construir()
@export_range(1, 200) var ancho_casillas: int = 1:
	set(valor):
		ancho_casillas = valor
		if is_node_ready():
			_construir()

var _oleaje: Line2D = null
var _tiempo: float = 0.0


func _ready() -> void:
	_construir()
	if not Engine.is_editor_hint():
		body_entered.connect(_al_entrar_cuerpo)


func _process(delta: float) -> void:
	if _oleaje == null:
		return
	# Línea de oleaje animada
	_tiempo += delta
	for i in range(_oleaje.get_point_count()):
		var punto: Vector2 = _oleaje.get_point_position(i)
		punto.y = 6.0 + sin(_tiempo * 3.0 + punto.x * 0.08) * 3.0
		_oleaje.set_point_position(i, punto)


func _al_entrar_cuerpo(cuerpo: Node2D) -> void:
	if not cuerpo is Jugador:
		return
	if tipo == "agua":
		Juego.morir("El agua helada de la quebrada te arrastró.")
	else:
		Juego.morir("Las espinas te hicieron soltar la linterna.")


## Crea la colisión y el marcador según el tipo y el ancho.
func _construir() -> void:
	var ancho: float = ancho_casillas * CASILLA
	var visual: Node2D = $Visual
	for hijo: Node in visual.get_children():
		hijo.queue_free()
	_oleaje = null

	var forma: RectangleShape2D = RectangleShape2D.new()
	var colision: CollisionShape2D = $CollisionShape2D
	colision.shape = forma

	if tipo == "agua":
		# Toda la casilla, con el borde superior un poco más abajo para no morir "rozando"
		forma.size = Vector2(ancho, CASILLA - 12.0)
		colision.position = Vector2(ancho / 2.0, CASILLA / 2.0 + 6.0)
		var agua: ColorRect = ColorRect.new()
		agua.mouse_filter = Control.MOUSE_FILTER_IGNORE
		agua.color = COLOR_AGUA
		agua.size = Vector2(ancho, CASILLA)
		visual.add_child(agua)
		_oleaje = Line2D.new()
		_oleaje.width = 3.0
		_oleaje.default_color = COLOR_OLEAJE
		_oleaje.material = Efectos.material_sin_sombra()
		var x: float = 0.0
		while x <= ancho:
			_oleaje.add_point(Vector2(x, 6.0))
			x += 12.0
		visual.add_child(_oleaje)
	else:
		# Espinas: mitad inferior de la casilla
		forma.size = Vector2(ancho - 8.0, CASILLA / 2.0)
		colision.position = Vector2(ancho / 2.0, CASILLA * 0.75)
		var paso: float = CASILLA / 3.0
		for i in range(ancho_casillas * 3):
			var triangulo: Polygon2D = Polygon2D.new()
			var x0: float = i * paso
			triangulo.polygon = PackedVector2Array([
				Vector2(x0, CASILLA),
				Vector2(x0 + paso / 2.0, CASILLA * 0.4),
				Vector2(x0 + paso, CASILLA),
			])
			triangulo.color = COLOR_ESPINAS
			triangulo.material = Efectos.material_sin_sombra()
			visual.add_child(triangulo)
