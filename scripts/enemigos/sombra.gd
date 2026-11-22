extends Area2D
## Sombra de la Bruma. No se puede destruir: la luz solo la asusta.
##  - "patrulla": va y viene entre limite_izq y limite_der.
##  - "cazadora": persigue a Lía si está cerca.
## Al tocar a Lía (sin estar asustada) le quita 25 de luz.
## Origen = centro inferior de la casilla; el cuerpo (72x72) está centrado en (0, -36).

const CASILLA: float = 48.0
const VELOCIDAD_PATRULLA: float = 105.0
const VELOCIDAD_CAZA: float = 142.0
const VELOCIDAD_CAZA_CUEVA: float = 168.0
const VELOCIDAD_VERTICAL: float = 60.0
const VELOCIDAD_HUIDA: float = 255.0
const RANGO_CAZA_X: float = 10.0 * CASILLA
const RANGO_CAZA_Y: float = 6.0 * CASILLA
const LIMITE_VERTICAL: float = 3.0 * CASILLA
const TIEMPO_SUSTO: float = 0.9
const DANO: float = 25.0
const CENTRO: Vector2 = Vector2(0.0, -36.0)

@export_enum("patrulla", "cazadora") var tipo: String = "patrulla"
@export var limite_izq: float = 0.0     # px globales
@export var limite_der: float = 0.0     # px globales

@onready var visual: Node2D = $Visual

var _inicio: Vector2 = Vector2.ZERO
var _direccion: float = 1.0
var _asustada: float = 0.0
var _tiempo: float = 0.0


func _ready() -> void:
	add_to_group("sombras")
	_inicio = global_position
	if limite_izq == 0.0 and limite_der == 0.0:
		limite_izq = _inicio.x - 4.0 * CASILLA
		limite_der = _inicio.x + 4.0 * CASILLA
	_tiempo = randf() * TAU
	_construir_visual()


## Vuelve a su posición inicial (cuando Lía reaparece).
func reiniciar() -> void:
	global_position = _inicio
	_direccion = 1.0
	_asustada = 0.0


func esta_asustada() -> bool:
	return _asustada > 0.0 or Juego.todas_asustadas


func _physics_process(delta: float) -> void:
	_tiempo += delta
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return

	if jugador.esta_iluminado(global_position + CENTRO):
		_asustada = TIEMPO_SUSTO
	else:
		_asustada = maxf(_asustada - delta, 0.0)

	if esta_asustada():
		_huir(jugador, delta)
	elif tipo == "cazadora":
		_cazar(jugador, delta)
	else:
		_patrullar(delta)

	global_position.x = clampf(global_position.x, limite_izq, limite_der)
	_actualizar_visual(delta)

	if not esta_asustada() and not jugador.muerto and overlaps_body(jugador):
		jugador.recibir_dano(DANO, global_position.x)


func _patrullar(delta: float) -> void:
	global_position.x += VELOCIDAD_PATRULLA * _direccion * delta
	if global_position.x >= limite_der:
		_direccion = -1.0
	elif global_position.x <= limite_izq:
		_direccion = 1.0


func _cazar(jugador: Jugador, delta: float) -> void:
	var diferencia: Vector2 = jugador.global_position - global_position
	var objetivo_y: float = _inicio.y
	if absf(diferencia.x) < RANGO_CAZA_X and absf(diferencia.y) < RANGO_CAZA_Y and not jugador.muerto:
		var velocidad: float = VELOCIDAD_CAZA_CUEVA if Juego.en_cueva else VELOCIDAD_CAZA
		global_position.x = move_toward(global_position.x, jugador.global_position.x, velocidad * delta)
		objetivo_y = clampf(jugador.global_position.y, _inicio.y - LIMITE_VERTICAL, _inicio.y + LIMITE_VERTICAL)
	global_position.y = move_toward(global_position.y, objetivo_y, VELOCIDAD_VERTICAL * delta)


func _huir(jugador: Jugador, delta: float) -> void:
	var lado: float = signf(global_position.x - jugador.global_position.x)
	if lado == 0.0:
		lado = 1.0
	global_position.x += VELOCIDAD_HUIDA * lado * delta


func _actualizar_visual(delta: float) -> void:
	# Flota +-3 px; asustada se ve más pequeña y transparente
	visual.position.y = CENTRO.y + sin(_tiempo * 2.5) * 3.0
	var asustada: bool = esta_asustada()
	var escala_objetivo: float = 0.7 if asustada else 1.0
	var alfa_objetivo: float = 0.45 if asustada else 1.0
	var escala: float = move_toward(visual.scale.x, escala_objetivo, 3.0 * delta)
	visual.scale = Vector2(escala, escala)
	visual.modulate.a = move_toward(visual.modulate.a, alfa_objetivo, 4.0 * delta)


## Marcador 72x72: mancha oscura violeta con dos ojos rojos que brillan en la oscuridad.
func _construir_visual() -> void:
	visual.position = CENTRO   # el cuerpo se dibuja alrededor de (0, 0) para encogerse desde su centro
	var cuerpo: Polygon2D = Polygon2D.new()
	var puntos: PackedVector2Array = PackedVector2Array()
	for i in range(20):
		var angulo: float = TAU * i / 20.0
		var radio: float = 36.0 * (0.9 + 0.1 * sin(angulo * 5.0))
		puntos.append(Vector2(cos(angulo), sin(angulo)) * radio)
	cuerpo.polygon = puntos
	cuerpo.color = Color(0.09, 0.05, 0.13, 0.95)
	visual.add_child(cuerpo)
	for lado: float in [-1.0, 1.0]:
		var ojo: ColorRect = ColorRect.new()
		ojo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ojo.color = Color(1.0, 0.15, 0.1)
		ojo.size = Vector2(10.0, 7.0)
		ojo.position = Vector2(lado * 12.0 - 5.0, -10.0)
		ojo.material = Efectos.material_sin_sombra()
		visual.add_child(ojo)
	var brillo: PointLight2D = PointLight2D.new()
	brillo.texture = Efectos.textura_radial()
	brillo.texture_scale = Efectos.escala_para_radio(40.0)
	brillo.color = Color(1.0, 0.2, 0.15)
	brillo.energy = 0.5
	brillo.position = Vector2(0.0, -7.0)
	visual.add_child(brillo)
