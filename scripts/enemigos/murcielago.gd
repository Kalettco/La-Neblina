extends Enemigo
## Murciélago de bruma (acto 2) · vida 1 · 48x32. Aparece en enjambres de 3 a 6.
## Cuelga quieto hasta que ve a Lía cerca; entonces vuela hacia ella ondulando (260 px/s).
## Al tocarla rebota hacia atrás. Si la linterna lo ilumina, huye un momento.
## Origen = centro inferior de la casilla; el cuerpo está centrado en (0, -16).

const CASILLA: float = 48.0
const CENTRO: Vector2 = Vector2(0.0, -16.0)
const VELOCIDAD: float = 260.0
const VELOCIDAD_HUIDA: float = 300.0
const RANGO_DESPERTAR: float = 9.0 * CASILLA
const ONDULACION: float = 150.0          # px/s de lado a lado
const FRECUENCIA: float = 7.0
const TIEMPO_SUSTO: float = 0.8
const TIEMPO_REBOTE: float = 0.6
const VELOCIDAD_REBOTE: float = 340.0

## Desfase del aleteo y de la onda (lo pone el enjambre para que no vuelen iguales).
var fase: float = 0.0

var _inicio: Vector2 = Vector2.ZERO
var _despierto: bool = false
var _asustado: float = 0.0
var _rebote: float = 0.0
var _direccion_rebote: Vector2 = Vector2.ZERO
var _tiempo: float = 0.0
var _alas: Array[Polygon2D] = []


func _ready() -> void:
	super._ready()
	add_to_group("murcielagos")
	_inicio = global_position
	_tiempo = fase
	_construir_visual()


func centro() -> Vector2:
	return global_position + CENTRO


func reiniciar() -> void:
	super.reiniciar()
	global_position = _inicio
	_despierto = false
	_asustado = 0.0
	_rebote = 0.0


func esta_asustado() -> bool:
	return _asustado > 0.0 or Juego.todas_asustadas


func puede_danar() -> bool:
	return super.puede_danar() and not esta_asustado() and _rebote <= 0.0


func _physics_process(delta: float) -> void:
	_tiempo += delta
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return
	var objetivo: Vector2 = jugador.global_position + Vector2(0.0, -42.0)

	if Juego.esta_iluminado(centro()):
		_asustado = TIEMPO_SUSTO
		_despierto = true
	else:
		_asustado = maxf(_asustado - delta, 0.0)
	_rebote = maxf(_rebote - delta, 0.0)
	if not _despierto and not jugador.muerto and centro().distance_to(objetivo) < RANGO_DESPERTAR \
			and _ve_a(objetivo):
		_despierto = true

	var velocidad: Vector2 = Vector2.ZERO
	if _rebote > 0.0:
		velocidad = _direccion_rebote * VELOCIDAD_REBOTE
	elif esta_asustado():
		velocidad = (centro() - objetivo).normalized() * VELOCIDAD_HUIDA
	elif _despierto and not jugador.muerto:
		var hacia: Vector2 = (objetivo - centro()).normalized()
		var lado: Vector2 = Vector2(-hacia.y, hacia.x)
		velocidad = hacia * VELOCIDAD + lado * sin(_tiempo * FRECUENCIA) * ONDULACION
	elif not _despierto:
		# Cuelga en su sitio y se mece un poco
		var reposo: Vector2 = _inicio + Vector2(0.0, sin(_tiempo * 2.0) * 4.0)
		global_position = global_position.move_toward(reposo, 60.0 * delta)
	global_position += velocidad * delta

	_actualizar_visual(delta)
	procesar_comunes(delta)
	# Si tocó a Lía (le haya hecho daño o no), rebota hacia atrás
	if not derrotado and _rebote <= 0.0 and not jugador.muerto and overlaps_body(jugador):
		_rebote = TIEMPO_REBOTE
		_direccion_rebote = (centro() - objetivo).normalized()


## ¿Lía está sin paredes en medio?
func _ve_a(objetivo: Vector2) -> bool:
	var consulta: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(centro(), objetivo, 1)
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


func _actualizar_visual(delta: float) -> void:
	# Aleteo: rápido al volar, lento colgado
	var aleteo: float = sin(_tiempo * (22.0 if _despierto else 5.0))
	for ala: Polygon2D in _alas:
		ala.scale.y = 0.35 + 0.65 * absf(aleteo)
	visual.position = CENTRO
	visual.modulate.a = move_toward(visual.modulate.a, 0.5 if esta_asustado() else 1.0, 4.0 * delta)


## Marcador 48x32: cuerpo violeta oscuro, dos alas y ojos rojos.
func _construir_visual() -> void:
	visual.position = CENTRO
	for lado: float in [-1.0, 1.0]:
		var ala: Polygon2D = Polygon2D.new()
		ala.polygon = PackedVector2Array([
			Vector2(lado * 6.0, -4.0), Vector2(lado * 24.0, -14.0),
			Vector2(lado * 20.0, 2.0), Vector2(lado * 12.0, 6.0)])
		ala.color = Color(0.16, 0.07, 0.22, 0.95)
		visual.add_child(ala)
		_alas.append(ala)
	var cuerpo: Polygon2D = Polygon2D.new()
	var puntos: PackedVector2Array = PackedVector2Array()
	for i in range(12):
		var angulo: float = TAU * i / 12.0
		puntos.append(Vector2(cos(angulo) * 9.0, sin(angulo) * 12.0))
	cuerpo.polygon = puntos
	cuerpo.color = Color(0.1, 0.05, 0.14, 1.0)
	visual.add_child(cuerpo)
	for lado: float in [-1.0, 1.0]:
		var ojo: ColorRect = ColorRect.new()
		ojo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ojo.color = Color(1.0, 0.2, 0.15)
		ojo.size = Vector2(4.0, 4.0)
		ojo.position = Vector2(lado * 4.0 - 2.0, -6.0)
		ojo.material = Efectos.material_sin_sombra()
		visual.add_child(ojo)
