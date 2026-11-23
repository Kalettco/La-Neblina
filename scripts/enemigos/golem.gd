extends Enemigo
## Gólem de bruma (acto 2, mini-jefe) · vida 10 · 144x192.
## Lento (80 px/s): camina por el suelo entre limite_izq y limite_der.
## CORAZA: solo recibe daño mientras lo ilumina la linterna o el campo de luz
## (las placas de la coraza se ven disueltas). La luz de la chispa sola no basta.
## GOLPE AL SUELO si Lía está a menos de 3 casillas: aviso de 0,6 s (levanta los brazos)
## y una onda de 4 casillas a cada lado que solo daña a quien esté en el suelo.
## Si Lía muere, recupera toda su vida.
## Origen = pies (centro inferior); el cuerpo está centrado en (0, -96).

const CASILLA: float = 48.0
const CENTRO: Vector2 = Vector2(0.0, -96.0)
const MEDIO_ANCHO: float = 72.0
const VELOCIDAD: float = 80.0
const RANGO_VISTA: float = 12.0 * CASILLA
const DISTANCIA_GOLPE: float = 3.0 * CASILLA
const ALCANCE_ONDA: float = 4.0 * CASILLA      # desde cada costado del cuerpo
const TIEMPO_AVISO: float = 0.6
const TIEMPO_RECUPERAR: float = 1.4
const DANO_ONDA: float = 25.0
const ESPERA_AVISO_CORAZA: float = 4.0         # segundos entre avisos "la coraza resiste"
const COLOR_CUERPO: Color = Color(0.16, 0.13, 0.2)
const COLOR_CORAZA: Color = Color(0.32, 0.3, 0.38)
const COLOR_NUCLEO: Color = Color(0.65, 0.3, 0.85)
const COLOR_AVISO: Color = Color(1.0, 0.3, 0.2)

enum Estado { CAMINANDO, AVISANDO, RECUPERANDO }

@export var limite_izq: float = 0.0     # px globales
@export var limite_der: float = 0.0
@export var nombre_jefe: String = "Gólem de bruma"   # barra de vida grande en el HUD

var _barra_visible: bool = false

var _inicio: Vector2 = Vector2.ZERO
var _estado: Estado = Estado.CAMINANDO
var _reloj: float = 0.0
var _direccion: float = -1.0
var _iluminado: bool = false
var _espera_aviso: float = 0.0
var _tiempo: float = 0.0
var _placas: Array[ColorRect] = []
var _brazos: Array[Node2D] = []
var _nucleo: Polygon2D = null


func _ready() -> void:
	super._ready()
	add_to_group("golems")
	_inicio = global_position
	if limite_izq == 0.0 and limite_der == 0.0:
		limite_izq = _inicio.x - 5.0 * CASILLA
		limite_der = _inicio.x + 5.0 * CASILLA
	_construir_visual()


func centro() -> Vector2:
	return global_position + CENTRO


func reiniciar() -> void:
	super.reiniciar()
	vida = vida_maxima
	global_position = _inicio
	_estado = Estado.CAMINANDO
	_reloj = 0.0
	_ocultar_barra()


func _exit_tree() -> void:
	_ocultar_barra()


## La barra aparece cuando Lía se acerca por primera vez.
func _mostrar_barra() -> void:
	_barra_visible = true
	Juego.avisar_jefe(nombre_jefe, vida, vida_maxima)


func _ocultar_barra() -> void:
	if _barra_visible:
		_barra_visible = false
		Juego.ocultar_jefe()


## Con la coraza puesta (sin luz) las chispas rebotan.
func recibir_dano(cantidad: int, desde: Vector2) -> void:
	if derrotado:
		return
	# Se calcula en el momento (el pulso del campo llega el mismo cuadro en que se enciende)
	var jugador: Jugador = Juego.jugador
	_iluminado = is_instance_valid(jugador) and _esta_iluminado(jugador)
	if not _iluminado:
		Efectos.estallido(get_parent(), desde, Color(0.6, 0.6, 0.65), 6)
		if _espera_aviso <= 0.0:
			_espera_aviso = ESPERA_AVISO_CORAZA
			Juego.toast("La coraza del gólem resiste. Ilumínalo con la linterna mientras le disparas.")
		return
	super.recibir_dano(cantidad, desde)
	_retroceso = Vector2.ZERO   # es demasiado pesado para retroceder
	if not derrotado:
		_mostrar_barra()


func morir() -> void:
	if derrotado:
		return
	Juego.sacudir_camara(12.0, 0.6)
	Efectos.estallido(get_parent(), centro() + Vector2(0.0, -50.0), COLOR_HUMO, 40)
	_ocultar_barra()
	super.morir()


func _physics_process(delta: float) -> void:
	_tiempo += delta
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return
	_iluminado = _esta_iluminado(jugador)
	_espera_aviso = maxf(_espera_aviso - delta, 0.0)
	if not _barra_visible and not jugador.muerto and centro().distance_to(jugador.global_position) < RANGO_VISTA:
		_mostrar_barra()

	match _estado:
		Estado.CAMINANDO:
			_caminar(jugador, delta)
		Estado.AVISANDO:
			_reloj -= delta
			if _reloj <= 0.0:
				_golpear(jugador)
				_estado = Estado.RECUPERANDO
				_reloj = TIEMPO_RECUPERAR
		Estado.RECUPERANDO:
			_reloj -= delta
			if _reloj <= 0.0:
				_estado = Estado.CAMINANDO

	global_position.x = clampf(global_position.x, limite_izq, limite_der)
	global_position.y = _inicio.y
	_actualizar_visual(delta)
	procesar_comunes(delta)


## Va hacia Lía si la ve cerca; si no, patrulla. Si está a menos de 3 casillas, avisa el golpe.
func _caminar(jugador: Jugador, delta: float) -> void:
	var diferencia: Vector2 = jugador.global_position - global_position
	var cerca: bool = not jugador.muerto and absf(diferencia.y) < 4.0 * CASILLA
	if cerca and absf(diferencia.x) < DISTANCIA_GOLPE:
		_estado = Estado.AVISANDO
		_reloj = TIEMPO_AVISO
		return
	if cerca and absf(diferencia.x) < RANGO_VISTA:
		_direccion = signf(diferencia.x) if diferencia.x != 0.0 else _direccion
	elif global_position.x >= limite_der:
		_direccion = -1.0
	elif global_position.x <= limite_izq:
		_direccion = 1.0
	global_position.x += _direccion * VELOCIDAD * delta


## Onda en el suelo: daña a Lía solo si está en el suelo y dentro del alcance.
func _golpear(jugador: Jugador) -> void:
	Audio.sfx_golem_golpe()
	Juego.sacudir_camara(10.0, 0.35)
	_crear_onda()
	if jugador.muerto or not jugador.is_on_floor():
		return
	var distancia_x: float = absf(jugador.global_position.x - global_position.x)
	if distancia_x <= MEDIO_ANCHO + ALCANCE_ONDA and absf(jugador.global_position.y - global_position.y) < CASILLA:
		jugador.recibir_dano(DANO_ONDA, global_position.x)


## Lo ilumina la linterna o el campo (cualquiera de 5 puntos del cuerpo).
func _esta_iluminado(jugador: Jugador) -> bool:
	for punto: Vector2 in [Vector2.ZERO, Vector2(0.0, -60.0), Vector2(0.0, 60.0), Vector2(-50.0, 0.0), Vector2(50.0, 0.0)]:
		var p: Vector2 = centro() + punto
		if jugador.esta_iluminado(p) or jugador.campo_ilumina(p):
			return true
	return false


## Dos franjas de luz morada que se abren por el suelo hacia ambos lados.
func _crear_onda() -> void:
	var contenedor: Node = get_parent()
	for lado: float in [-1.0, 1.0]:
		var onda: ColorRect = ColorRect.new()
		onda.mouse_filter = Control.MOUSE_FILTER_IGNORE
		onda.color = Color(0.7, 0.35, 0.95, 0.8)
		onda.material = Efectos.material_sin_sombra()
		onda.size = Vector2(0.0, 18.0)
		var inicio_x: float = global_position.x + lado * MEDIO_ANCHO
		onda.position = Vector2(inicio_x, global_position.y - 18.0)
		contenedor.add_child(onda)
		var tween: Tween = onda.create_tween()
		tween.set_parallel(true)
		tween.tween_property(onda, "size:x", ALCANCE_ONDA, 0.25)
		if lado < 0.0:
			tween.tween_property(onda, "position:x", inicio_x - ALCANCE_ONDA, 0.25)
		tween.tween_property(onda, "modulate:a", 0.0, 0.45)
		tween.chain().tween_callback(onda.queue_free)


func _actualizar_visual(delta: float) -> void:
	# Camina meciéndose; al avisar levanta los brazos y el núcleo se pone rojo
	var paso: float = sin(_tiempo * 4.0) * 3.0 if _estado == Estado.CAMINANDO else 0.0
	visual.position = CENTRO + Vector2(0.0, paso)
	visual.scale.x = 1.0 if _direccion >= 0.0 else -1.0
	var avisando: bool = _estado == Estado.AVISANDO
	for i in range(_brazos.size()):
		var objetivo: float = -2.4 if avisando else 0.0
		var brazo: Node2D = _brazos[i]
		brazo.rotation = move_toward(brazo.rotation, objetivo * (1.0 if i == 0 else -1.0), 8.0 * delta)
	_nucleo.color = COLOR_AVISO if avisando else COLOR_NUCLEO
	# La coraza se disuelve mientras está iluminado
	var alfa_coraza: float = 0.2 if _iluminado else 1.0
	for placa: ColorRect in _placas:
		placa.modulate.a = move_toward(placa.modulate.a, alfa_coraza, 5.0 * delta)
	visual.modulate.a = move_toward(visual.modulate.a, 1.0, 2.0 * delta)


## Marcador 144x192: bloque de bruma con placas de coraza, brazos y un núcleo morado.
func _construir_visual() -> void:
	visual.position = CENTRO
	var cuerpo: Polygon2D = Polygon2D.new()
	cuerpo.polygon = PackedVector2Array([
		Vector2(-60.0, -96.0), Vector2(60.0, -96.0), Vector2(72.0, -20.0),
		Vector2(64.0, 96.0), Vector2(-64.0, 96.0), Vector2(-72.0, -20.0)])
	cuerpo.color = COLOR_CUERPO
	visual.add_child(cuerpo)
	for rect: Rect2 in [Rect2(-56, -88, 50, 40), Rect2(6, -88, 50, 40), Rect2(-62, -40, 40, 56),
			Rect2(22, -40, 40, 56), Rect2(-58, 26, 116, 30)]:
		var placa: ColorRect = ColorRect.new()
		placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		placa.color = COLOR_CORAZA
		placa.position = rect.position
		placa.size = rect.size
		visual.add_child(placa)
		_placas.append(placa)
	for lado: float in [-1.0, 1.0]:
		var hombro: Node2D = Node2D.new()
		hombro.position = Vector2(lado * 66.0, -60.0)
		var brazo: ColorRect = ColorRect.new()
		brazo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		brazo.color = COLOR_CORAZA.darkened(0.2)
		brazo.position = Vector2(-14.0, 0.0)
		brazo.size = Vector2(28.0, 100.0)
		hombro.add_child(brazo)
		visual.add_child(hombro)
		_brazos.append(hombro)
	_nucleo = Polygon2D.new()
	var puntos: PackedVector2Array = PackedVector2Array()
	for i in range(12):
		var angulo: float = TAU * i / 12.0
		puntos.append(Vector2(cos(angulo), sin(angulo)) * 16.0)
	_nucleo.polygon = puntos
	_nucleo.position = Vector2(0.0, -20.0)
	_nucleo.material = Efectos.material_sin_sombra()
	visual.add_child(_nucleo)
	for lado: float in [-1.0, 1.0]:
		var ojo: ColorRect = ColorRect.new()
		ojo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ojo.color = Color(1.0, 0.25, 0.15)
		ojo.size = Vector2(12.0, 8.0)
		ojo.position = Vector2(lado * 20.0 - 6.0, -72.0)
		ojo.material = Efectos.material_sin_sombra()
		visual.add_child(ojo)
	var brillo: PointLight2D = PointLight2D.new()
	brillo.texture = Efectos.textura_radial()
	brillo.texture_scale = Efectos.escala_para_radio(110.0)
	brillo.color = COLOR_NUCLEO
	brillo.energy = 0.6
	brillo.position = Vector2(0.0, -20.0)
	visual.add_child(brillo)
