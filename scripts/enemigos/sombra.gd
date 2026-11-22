extends Enemigo
## Sombra de la Bruma.
##  - "patrulla": va y viene entre limite_izq y limite_der.
##  - "cazadora": persigue a Lía si está cerca.
## La luz la asusta (huye y no hace daño). Al tocar a Lía le quita 25 de luz.
## Niveles 1 y 2: no se puede destruir (Lía no tiene con qué).
## Acto 2: vida 2; la cazadora hace una EMBESTIDA cuando Lía está a menos de 4 casillas.
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
const CENTRO: Vector2 = Vector2(0.0, -36.0)

# Embestida (solo cazadoras del acto 2)
const DISTANCIA_EMBESTIDA: float = 4.0 * CASILLA
const TIEMPO_AVISO: float = 0.5
const TIEMPO_EMBESTIDA: float = 0.4
const VELOCIDAD_EMBESTIDA: float = 500.0
const ESPERA_ENTRE_EMBESTIDAS: float = 1.5

enum Estado { NORMAL, AVISANDO, EMBISTIENDO }

@export_enum("patrulla", "cazadora") var tipo: String = "patrulla"
@export var limite_izq: float = 0.0     # px globales
@export var limite_der: float = 0.0     # px globales

var _inicio: Vector2 = Vector2.ZERO
var _direccion: float = 1.0
var _asustada: float = 0.0
var _tiempo: float = 0.0
var _estado: Estado = Estado.NORMAL
var _reloj_estado: float = 0.0
var _espera_embestida: float = 0.0
var _direccion_embestida: Vector2 = Vector2.ZERO
var _ojos: Array[ColorRect] = []
var _brillo_ojos: PointLight2D = null


func _ready() -> void:
	super._ready()
	add_to_group("sombras")
	_inicio = global_position
	if limite_izq == 0.0 and limite_der == 0.0:
		limite_izq = _inicio.x - 4.0 * CASILLA
		limite_der = _inicio.x + 4.0 * CASILLA
	_tiempo = randf() * TAU
	_construir_visual()


func centro() -> Vector2:
	return global_position + CENTRO


## Vuelve a su posición inicial (cuando Lía reaparece).
func reiniciar() -> void:
	super.reiniciar()
	global_position = _inicio
	_direccion = 1.0
	_asustada = 0.0
	_estado = Estado.NORMAL
	_espera_embestida = 0.0


func esta_asustada() -> bool:
	return _asustada > 0.0 or Juego.todas_asustadas


func puede_danar() -> bool:
	return super.puede_danar() and not esta_asustada()


## En los niveles 1 y 2 la sombra no se puede destruir.
func recibir_dano(cantidad: int, desde: Vector2) -> void:
	if not Juego.es_acto_2():
		return
	super.recibir_dano(cantidad, desde)


func _physics_process(delta: float) -> void:
	_tiempo += delta
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return

	if Juego.esta_iluminado(centro()):
		_asustada = TIEMPO_SUSTO
		_estado = Estado.NORMAL   # la luz interrumpe la embestida
	else:
		_asustada = maxf(_asustada - delta, 0.0)
	_espera_embestida = maxf(_espera_embestida - delta, 0.0)

	if esta_asustada():
		_huir(jugador, delta)
	elif _estado != Estado.NORMAL:
		_procesar_embestida(delta)
	elif tipo == "cazadora":
		_cazar(jugador, delta)
	else:
		_patrullar(delta)

	global_position.x = clampf(global_position.x, limite_izq, limite_der)
	global_position.y = clampf(global_position.y, _inicio.y - LIMITE_VERTICAL, _inicio.y + LIMITE_VERTICAL)
	_actualizar_visual(delta)
	procesar_comunes(delta)


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
		# Acto 2: si está muy cerca, prepara la embestida
		if Juego.es_acto_2() and _espera_embestida <= 0.0 and diferencia.length() < DISTANCIA_EMBESTIDA:
			_estado = Estado.AVISANDO
			_reloj_estado = TIEMPO_AVISO
			return
		var velocidad: float = VELOCIDAD_CAZA_CUEVA if Juego.en_cueva else VELOCIDAD_CAZA
		global_position.x = move_toward(global_position.x, jugador.global_position.x, velocidad * delta)
		objetivo_y = clampf(jugador.global_position.y, _inicio.y - LIMITE_VERTICAL, _inicio.y + LIMITE_VERTICAL)
	global_position.y = move_toward(global_position.y, objetivo_y, VELOCIDAD_VERTICAL * delta)


## Se detiene 0,5 s (ojos más brillantes) y se lanza hacia Lía 0,4 s a 500 px/s.
func _procesar_embestida(delta: float) -> void:
	_reloj_estado -= delta
	if _estado == Estado.AVISANDO:
		if _reloj_estado <= 0.0:
			var jugador: Jugador = Juego.jugador
			var objetivo: Vector2 = jugador.global_position + Vector2(0.0, -42.0)
			_direccion_embestida = (objetivo - centro()).normalized()
			_estado = Estado.EMBISTIENDO
			_reloj_estado = TIEMPO_EMBESTIDA
	elif _estado == Estado.EMBISTIENDO:
		global_position += _direccion_embestida * VELOCIDAD_EMBESTIDA * delta
		if _reloj_estado <= 0.0:
			_estado = Estado.NORMAL
			_espera_embestida = ESPERA_ENTRE_EMBESTIDAS


func _huir(jugador: Jugador, delta: float) -> void:
	var lado: float = signf(global_position.x - jugador.global_position.x)
	if lado == 0.0:
		lado = 1.0
	global_position.x += VELOCIDAD_HUIDA * lado * delta


func _actualizar_visual(delta: float) -> void:
	# Flota +-3 px (tiembla al avisar); asustada se ve más pequeña y transparente
	var temblor: float = randf_range(-3.0, 3.0) if _estado == Estado.AVISANDO else 0.0
	visual.position = CENTRO + Vector2(temblor, sin(_tiempo * 2.5) * 3.0)
	var asustada: bool = esta_asustada()
	var escala_objetivo: float = 0.7 if asustada else 1.0
	var alfa_objetivo: float = 0.45 if asustada else 1.0
	var escala: float = move_toward(visual.scale.x, escala_objetivo, 3.0 * delta)
	visual.scale = Vector2(escala, escala)
	visual.modulate.a = move_toward(visual.modulate.a, alfa_objetivo, 4.0 * delta)
	# Ojos más brillantes mientras avisa o embiste
	var alerta: bool = _estado != Estado.NORMAL
	for ojo: ColorRect in _ojos:
		ojo.color = Color(1.0, 0.85, 0.4) if alerta else Color(1.0, 0.15, 0.1)
		ojo.scale = Vector2(1.4, 1.4) if alerta else Vector2.ONE
	_brillo_ojos.energy = 1.4 if alerta else 0.5


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
		ojo.pivot_offset = Vector2(5.0, 3.5)
		ojo.position = Vector2(lado * 12.0 - 5.0, -10.0)
		ojo.material = Efectos.material_sin_sombra()
		visual.add_child(ojo)
		_ojos.append(ojo)
	_brillo_ojos = PointLight2D.new()
	_brillo_ojos.texture = Efectos.textura_radial()
	_brillo_ojos.texture_scale = Efectos.escala_para_radio(40.0)
	_brillo_ojos.color = Color(1.0, 0.2, 0.15)
	_brillo_ojos.energy = 0.5
	_brillo_ojos.position = Vector2(0.0, -7.0)
	visual.add_child(_brillo_ojos)
