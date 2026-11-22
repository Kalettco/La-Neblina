class_name Jugador
extends CharacterBody2D
## Lía: movimiento lateral, salto y linterna (mecánica principal).
## Medidas para HD (1920 x 1080, casillas de 48 px).

# --- Movimiento ---
@export var velocidad: float = 350.0          # px por segundo
@export var aceleracion: float = 3000.0       # qué tan rápido arranca
@export var friccion: float = 3200.0          # qué tan rápido frena

# --- Salto ---
@export var fuerza_salto: float = 950.0       # unas 3,5 casillas de alto
@export var gravedad: float = 2600.0
@export var caida_maxima: float = 1400.0
@export var tiempo_coyote: float = 0.10       # salto permitido justo después de salir de un borde
@export var tiempo_buffer_salto: float = 0.12 # salto recordado si presionas justo antes de aterrizar

# --- Linterna ---
@export var energia_maxima: float = 100.0
@export var gasto_por_segundo: float = 13.0   # unos 7,7 s de luz continua
@export var alcance_luz: float = 420.0        # px
@export var apertura_luz: float = 0.36        # radianes a cada lado del centro del cono
@export var color_luz: Color = Color(1.0, 0.86, 0.55)
@export var radio_pies: float = 60.0          # la linterna también ilumina alrededor (plataforma bajo los pies)

const ENERGIA_BAJA: float = 25.0
const ENERGIA_AL_REAPARECER: float = 70.0
const TAMANO_TEXTURA_CONO: int = 512

var mirando: int = 1    # 1 = derecha, -1 = izquierda
var _coyote: float = 0.0
var _buffer: float = 0.0

var energia: float = 100.0
var linterna_encendida: bool = false
var angulo_cono: float = 0.0            # ángulo global del cono (radianes)
var _tiempo: float = 0.0                # reloj para el parpadeo del aura
var _energia_avisada: float = -1.0      # último valor enviado al HUD

# --- Animación (para cuando llegue el arte) ---
var _estaba_en_suelo: bool = true
var _tiempo_aterrizar: float = 0.0
var muerto: bool = false
var recibiendo_dano: bool = false
var entregando_luz: bool = false

@onready var visual: Node2D = $Visual
@onready var punto_linterna: Marker2D = $PuntoLinterna
@onready var cono: PointLight2D = $PuntoLinterna/Cono
@onready var aura: PointLight2D = $Aura


func _ready() -> void:
	add_to_group("jugador")
	energia = energia_maxima
	_preparar_luces()
	Juego.registrar_jugador(self)


func _physics_process(delta: float) -> void:
	_tiempo += delta
	_aplicar_gravedad(delta)
	_procesar_salto(delta)
	_procesar_movimiento(delta)
	move_and_slide()
	_procesar_linterna(delta)
	_actualizar_visual()
	_actualizar_aura()
	_avisar_energia()
	_actualizar_animacion(delta)


func _aplicar_gravedad(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravedad * delta, caida_maxima)


func _procesar_salto(delta: float) -> void:
	# Coyote time
	if is_on_floor():
		_coyote = tiempo_coyote
	else:
		_coyote -= delta

	# Buffer de salto
	if Input.is_action_just_pressed("saltar"):
		_buffer = tiempo_buffer_salto
	else:
		_buffer -= delta

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = -fuerza_salto
		_buffer = 0.0
		_coyote = 0.0

	# Salto variable: si sueltas el botón antes, salta más bajo
	if Input.is_action_just_released("saltar") and velocity.y < 0.0:
		velocity.y *= 0.5


func _procesar_movimiento(delta: float) -> void:
	var direccion: float = Input.get_axis("mover_izquierda", "mover_derecha")
	if direccion != 0.0:
		velocity.x = move_toward(velocity.x, direccion * velocidad, aceleracion * delta)
		mirando = 1 if direccion > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, friccion * delta)


# --- Linterna ---

func _procesar_linterna(delta: float) -> void:
	linterna_encendida = Input.is_action_pressed("linterna") and energia > 0.0
	if linterna_encendida:
		var raton: Vector2 = get_global_mouse_position()
		# Mientras la linterna está encendida, Lía mira hacia el mouse
		if absf(raton.x - global_position.x) > 1.0:
			mirando = 1 if raton.x > global_position.x else -1
		_colocar_punto_linterna()
		angulo_cono = (raton - punto_linterna.global_position).angle()
		cono.global_rotation = angulo_cono
		energia = maxf(energia - gasto_por_segundo * delta, 0.0)
		if energia <= 0.0:
			linterna_encendida = false
			morir("La Bruma te alcanzó.")
	cono.enabled = linterna_encendida


## Devuelve true si el punto está iluminado por la linterna:
## dentro del cono, o muy cerca de la linterna (regla de los pies).
func esta_iluminado(punto_global: Vector2) -> bool:
	if not linterna_encendida:
		return false
	var origen: Vector2 = punto_linterna.global_position
	var hacia_punto: Vector2 = punto_global - origen
	var distancia: float = hacia_punto.length()
	if distancia <= radio_pies:
		return true
	if distancia > alcance_luz:
		return false
	var diferencia: float = absf(wrapf(hacia_punto.angle() - angulo_cono, -PI, PI))
	return diferencia < apertura_luz


func morir(mensaje: String) -> void:
	Juego.morir(mensaje)


## La llama Juego: vuelve al último farol (o al inicio).
func reaparecer(posicion: Vector2) -> void:
	global_position = posicion
	velocity = Vector2.ZERO
	energia = clampf(maxf(ENERGIA_AL_REAPARECER, energia), 0.0, energia_maxima)
	linterna_encendida = false
	cono.enabled = false


## Suma luz (frascos, guardianas). Nunca pasa del máximo.
func recargar(cantidad: float) -> void:
	energia = minf(energia + cantidad, energia_maxima)


## Suma luz sin pasar de un límite (faroles: hasta 70).
func recargar_hasta(cantidad: float, limite: float) -> void:
	if energia < limite:
		energia = minf(energia + cantidad, limite)


# --- Visual ---

func _colocar_punto_linterna() -> void:
	punto_linterna.position.x = absf(punto_linterna.position.x) * mirando


func _actualizar_visual() -> void:
	visual.scale.x = mirando
	_colocar_punto_linterna()


func _actualizar_aura() -> void:
	# Más débil con poca luz: de 0.35 (vacía) a 0.9 (llena)
	var proporcion: float = energia / energia_maxima
	var brillo: float = lerpf(0.35, 0.9, proporcion)
	if energia < ENERGIA_BAJA:
		brillo *= 0.8 + 0.2 * sin(_tiempo * 6.0)   # parpadeo suave
	aura.energy = brillo


## Avisa al HUD solo cuando la energía cambia.
func _avisar_energia() -> void:
	if energia != _energia_avisada:
		_energia_avisada = energia
		Juego.energia_cambiada.emit(energia, energia_maxima)


func _preparar_luces() -> void:
	cono.texture = _crear_textura_cono()
	cono.texture_scale = alcance_luz / (TAMANO_TEXTURA_CONO / 2.0)
	cono.color = color_luz
	cono.enabled = false
	aura.texture = Efectos.textura_radial()
	aura.color = color_luz


## Cono: imagen 512x512, solo la mitad derecha.
## Alfa = suavizado en el borde del ángulo * (1 - distancia / radio).
func _crear_textura_cono() -> ImageTexture:
	var tamano: int = TAMANO_TEXTURA_CONO
	var radio: float = tamano / 2.0
	var centro: Vector2 = Vector2(radio, radio)
	var imagen: Image = Image.create(tamano, tamano, false, Image.FORMAT_RGBA8)
	imagen.fill(Color(1.0, 1.0, 1.0, 0.0))
	for y in range(tamano):
		for x in range(int(radio), tamano):
			var desde_centro: Vector2 = Vector2(x + 0.5, y + 0.5) - centro
			var distancia: float = desde_centro.length()
			if distancia >= radio:
				continue
			var angulo: float = absf(desde_centro.angle())
			var borde: float = 1.0 - smoothstep(apertura_luz * 0.7, apertura_luz, angulo)
			if borde <= 0.0:
				continue
			var alfa: float = borde * (1.0 - distancia / radio)
			imagen.set_pixel(x, y, Color(1.0, 1.0, 1.0, alfa))
	return ImageTexture.create_from_image(imagen)


# --- Animación (preparada para el AnimatedSprite2D "Sprite") ---

func _actualizar_animacion(delta: float) -> void:
	var en_suelo: bool = is_on_floor()
	if en_suelo and not _estaba_en_suelo:
		_tiempo_aterrizar = 0.17   # 2 cuadros a 12 fps
	_estaba_en_suelo = en_suelo
	_tiempo_aterrizar = maxf(_tiempo_aterrizar - delta, 0.0)

	var sprite: AnimatedSprite2D = get_node_or_null("Visual/Sprite") as AnimatedSprite2D
	if sprite == null:
		return
	var nombre: String = _elegir_animacion(en_suelo)
	if sprite.animation != nombre and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(nombre):
		sprite.play(nombre)


func _elegir_animacion(en_suelo: bool) -> String:
	if muerto:
		return "lia_desmayo"
	if entregando_luz:
		return "lia_entregar"
	if recibiendo_dano:
		return "lia_dano"
	if not en_suelo:
		return "lia_saltar" if velocity.y < 0.0 else "lia_caer"
	if _tiempo_aterrizar > 0.0:
		return "lia_aterrizar"
	if absf(velocity.x) > 10.0:
		return "lia_caminar"
	return "lia_idle"
