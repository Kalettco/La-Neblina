extends Enemigo
## Lanzadora de Bruma (acto 2) · vida 3 · 72x96.
## Flota en su sitio (+-8 px). Cada 2 s, si Lía está a menos de 12 casillas y la ve
## (sin paredes en medio), dispara una esquirla de bruma. Avisa 0,4 s antes (se infla).
## Si la linterna la ilumina, se asusta y no dispara.
## Origen = centro inferior de la casilla; el cuerpo está centrado en (0, -48).

const ESCENA_ESQUIRLA: PackedScene = preload("res://escenas/enemigos/esquirla.tscn")
const CASILLA: float = 48.0
const CENTRO: Vector2 = Vector2(0.0, -48.0)
const RANGO: float = 12.0 * CASILLA
const TIEMPO_ENTRE_DISPAROS: float = 2.0
const TIEMPO_AVISO: float = 0.4
const TIEMPO_SUSTO: float = 0.9

var _inicio: Vector2 = Vector2.ZERO
var _tiempo: float = 0.0
var _reloj_disparo: float = TIEMPO_ENTRE_DISPAROS
var _avisando: float = 0.0
var _asustada: float = 0.0
var _nucleo: Polygon2D = null


func _ready() -> void:
	super._ready()
	_inicio = global_position
	_tiempo = randf() * TAU
	_construir_visual()


func centro() -> Vector2:
	return global_position + CENTRO


func reiniciar() -> void:
	super.reiniciar()
	global_position = _inicio
	_reloj_disparo = TIEMPO_ENTRE_DISPAROS
	_avisando = 0.0
	_asustada = 0.0


func esta_asustada() -> bool:
	return _asustada > 0.0 or Juego.todas_asustadas


func puede_danar() -> bool:
	return super.puede_danar() and not esta_asustada()


func _physics_process(delta: float) -> void:
	_tiempo += delta
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return
	# Flota en su punto
	global_position.y = _inicio.y + sin(_tiempo * 1.8) * 8.0
	global_position.x = move_toward(global_position.x, _inicio.x, 120.0 * delta)

	if Juego.esta_iluminado(centro()):
		_asustada = TIEMPO_SUSTO
		_avisando = 0.0
	else:
		_asustada = maxf(_asustada - delta, 0.0)

	if not esta_asustada() and not jugador.muerto:
		if _avisando > 0.0:
			_avisando -= delta
			if _avisando <= 0.0:
				_disparar(jugador)
		else:
			_reloj_disparo -= delta
			if _reloj_disparo <= 0.0:
				_reloj_disparo = TIEMPO_ENTRE_DISPAROS
				if _ve_a(jugador):
					_avisando = TIEMPO_AVISO
	_actualizar_visual(delta)
	procesar_comunes(delta)


## ¿Lía está en rango y sin paredes en medio?
func _ve_a(jugador: Jugador) -> bool:
	var objetivo: Vector2 = jugador.global_position + Vector2(0.0, -42.0)
	if centro().distance_to(objetivo) > RANGO:
		return false
	var consulta: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(centro(), objetivo, 1)
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


func _disparar(jugador: Jugador) -> void:
	var objetivo: Vector2 = jugador.global_position + Vector2(0.0, -42.0)
	var esquirla: Node2D = ESCENA_ESQUIRLA.instantiate()
	esquirla.global_position = centro()
	esquirla.set("direccion", (objetivo - centro()).normalized())
	get_parent().add_child(esquirla)
	Audio.sfx_esquirla()


func _actualizar_visual(delta: float) -> void:
	# Se infla mientras avisa; asustada se encoge y se vuelve transparente
	var escala_objetivo: float = 1.0
	if _avisando > 0.0:
		escala_objetivo = 1.0 + 0.35 * (1.0 - _avisando / TIEMPO_AVISO)
	elif esta_asustada():
		escala_objetivo = 0.75
	var escala: float = move_toward(visual.scale.x, escala_objetivo, 3.0 * delta)
	visual.scale = Vector2(escala, escala)
	visual.modulate.a = move_toward(visual.modulate.a, 0.5 if esta_asustada() else 1.0, 4.0 * delta)
	_nucleo.color = Color(1.0, 0.4, 0.9) if _avisando > 0.0 else Color(0.7, 0.3, 0.85)


## Marcador 72x96: gota de bruma alargada con un núcleo morado que brilla.
func _construir_visual() -> void:
	visual.position = CENTRO
	var cuerpo: Polygon2D = Polygon2D.new()
	var puntos: PackedVector2Array = PackedVector2Array()
	for i in range(24):
		var angulo: float = TAU * i / 24.0
		puntos.append(Vector2(cos(angulo) * 36.0, sin(angulo) * 48.0))
	cuerpo.polygon = puntos
	cuerpo.color = Color(0.12, 0.06, 0.18, 0.95)
	visual.add_child(cuerpo)
	_nucleo = Polygon2D.new()
	var nucleo_puntos: PackedVector2Array = PackedVector2Array()
	for i in range(12):
		var angulo: float = TAU * i / 12.0
		nucleo_puntos.append(Vector2(cos(angulo), sin(angulo)) * 11.0)
	_nucleo.polygon = nucleo_puntos
	_nucleo.material = Efectos.material_sin_sombra()
	visual.add_child(_nucleo)
	var brillo: PointLight2D = PointLight2D.new()
	brillo.texture = Efectos.textura_radial()
	brillo.texture_scale = Efectos.escala_para_radio(60.0)
	brillo.color = Color(0.7, 0.3, 0.9)
	brillo.energy = 0.7
	visual.add_child(brillo)
