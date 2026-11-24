extends Node2D
## Árbol Madre: final del juego.
## Con las 3 guardianas, Lía mantiene E para entregarle TODA su luz.
## A los 3 s el árbol sana (5 s), la Bruma se va y Andrés queda libre.
## Origen = centro inferior de la casilla (base del tronco).

const TIEMPO_ENTREGA: float = 3.0
const TIEMPO_CURACION: float = 5.0
const GASTO_ENTREGA: float = 40.0        # luz por segundo mientras se mantiene E
const CENTRO_COPA: Vector2 = Vector2(0.0, -480.0)
const ARTE_ATRAPADO: String = "res://assets/sprites/andres_atrapado.png"    # cuadros de 96 x 48
const ARTE_DESPIERTA: String = "res://assets/sprites/andres_despierta.png"  # cuadros de 96 x 48

const COLOR_TRONCO_SECO: Color = Color(0.3, 0.27, 0.25)
const COLOR_COPA_SECA: Color = Color(0.26, 0.25, 0.24)
const COLOR_TRONCO_SANO: Color = Color(0.5, 0.36, 0.2)
const COLOR_COPA_SANA: Color = Color(0.45, 0.78, 0.35)
const COLOR_BRILLO_SANO: Color = Color(1.0, 0.85, 0.4)

const TEXTO_FALTAN: String = "El Árbol Madre está casi apagado. Necesita a las 3 luciérnagas guardianas y solo traes %d. Regresa a buscarlas."
const TEXTO_LISTO: String = "Papá está atrapado en las raíces. Mantén presionada E para entregarle toda tu luz al Árbol Madre."
const TEXTO_ENTREGANDO: String = "Sigue presionando E. Todo se queda a oscuras... y Lía no sale corriendo."

@onready var area: Area2D = $Area
@onready var tronco: CanvasItem = $Visual/Tronco
@onready var raices: CanvasItem = $Visual/Raices
@onready var copa: CanvasItem = $Visual/Copa
@onready var andres: Node2D = $Visual/Andres
@onready var sprite_andres: AnimatedSprite2D = $Visual/Andres/Sprite
@onready var raiz_andres: CanvasItem = $Visual/RaizAndres
@onready var brillo: PointLight2D = $Brillo
@onready var chispas_entrega: CPUParticles2D = $ChispasEntrega
@onready var chispas_curacion: CPUParticles2D = $ChispasCuracion

var contador: float = 0.0
var curado: bool = false
var _jugador_dentro: bool = false
var _entregando: bool = false


func _ready() -> void:
	brillo.texture = Efectos.textura_radial()
	brillo.texture_scale = Efectos.escala_para_radio(520.0)
	chispas_entrega.material = Efectos.material_sin_sombra()
	chispas_curacion.material = Efectos.material_sin_sombra()
	chispas_curacion.emission_rect_extents = Vector2(240.0, 300.0)
	chispas_curacion.position = Vector2(0.0, -330.0)
	tronco.modulate = COLOR_TRONCO_SECO
	raices.modulate = COLOR_TRONCO_SECO
	copa.modulate = COLOR_COPA_SECA
	_preparar_andres()


func _physics_process(delta: float) -> void:
	if curado:
		return
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return

	var dentro: bool = not jugador.muerto and area.overlaps_body(jugador)
	if not dentro:
		if _jugador_dentro:
			_terminar_entrega(jugador)
			Juego.mostrar_cartel("", false)
		_jugador_dentro = false
		contador = maxf(contador - delta, 0.0)
		return
	_jugador_dentro = true

	if Juego.guardianas() < 3:
		Juego.mostrar_cartel(TEXTO_FALTAN % Juego.guardianas(), false)
		return

	if Input.is_action_pressed("entregar_luz"):
		_entregar(jugador, delta)
	else:
		_terminar_entrega(jugador)
		contador = maxf(contador - delta, 0.0)
		Juego.mostrar_cartel(TEXTO_LISTO, false)

	if contador >= TIEMPO_ENTREGA:
		_curar(jugador)


func _entregar(jugador: Jugador, delta: float) -> void:
	if not _entregando:
		_entregando = true
		jugador.entregando_luz = true
		jugador.bloqueado = true
		Juego.entregando_luz = true
		Juego.todas_asustadas = true
	contador += delta
	jugador.energia = maxf(jugador.energia - GASTO_ENTREGA * delta, 0.0)
	Juego.mostrar_cartel(TEXTO_ENTREGANDO, false)
	# Partículas de luz que viajan de la linterna al árbol
	var origen: Vector2 = jugador.punto_linterna.global_position
	var destino: Vector2 = global_position + CENTRO_COPA * 0.5
	var hacia: Vector2 = destino - origen
	chispas_entrega.global_position = origen
	chispas_entrega.direction = hacia.normalized()
	chispas_entrega.initial_velocity_min = hacia.length() / chispas_entrega.lifetime
	chispas_entrega.initial_velocity_max = chispas_entrega.initial_velocity_min * 1.1
	chispas_entrega.emitting = true


func _terminar_entrega(jugador: Jugador) -> void:
	chispas_entrega.emitting = false
	if not _entregando:
		return
	_entregando = false
	jugador.entregando_luz = false
	jugador.bloqueado = false
	Juego.entregando_luz = false
	Juego.todas_asustadas = false


## CURACIÓN (5 s): el árbol se enciende desde las raíces, la oscuridad se aclara,
## suben cientos de partículas doradas y la raíz que cubre a Andrés desaparece.
func _curar(jugador: Jugador) -> void:
	curado = true
	chispas_entrega.emitting = false
	jugador.entregando_luz = true       # la linterna sigue apagada
	jugador.bloqueado = true
	Juego.entregando_luz = false
	Juego.todas_asustadas = true        # las sombras se van
	Juego.curando = true
	Juego.mostrar_cartel("", false)
	Juego.sacudir_camara(8.0, 0.6)
	Audio.sfx_curacion()
	chispas_curacion.emitting = true

	var tween: Tween = create_tween()
	tween.tween_property(raices, "modulate", COLOR_TRONCO_SANO, 1.0)
	tween.tween_property(tronco, "modulate", COLOR_TRONCO_SANO, 1.2)
	tween.tween_property(copa, "modulate", COLOR_COPA_SANA, 1.3)
	tween.parallel().tween_property(brillo, "energy", 1.6, 1.3)
	tween.parallel().tween_property(brillo, "color", COLOR_BRILLO_SANO, 1.3)
	tween.tween_callback(_despertar_andres)
	tween.tween_property(raiz_andres, "modulate:a", 0.0, 1.0)
	tween.tween_interval(TIEMPO_CURACION - 4.5)
	tween.tween_callback(_terminar_curacion)


func _terminar_curacion() -> void:
	for sombra: Node in get_tree().get_nodes_in_group("sombras"):
		var tween: Tween = sombra.create_tween()
		tween.tween_property(sombra, "modulate:a", 0.0, 0.8)
	Juego.completar_arbol()


# --- Andrés (AnimatedSprite2D Visual/Andres/Sprite, origen en el suelo) ---

## Arma "atrapado" (se repite) y "despierta" (una vez). andres_atrapado.png ya trae
## las raíces dibujadas: si sirve, se ocultan el marcador y la raíz hecha por código.
func _preparar_andres() -> void:
	var cuadros: SpriteFrames = Tiras.nuevas()
	Tiras.agregar(cuadros, ARTE_ATRAPADO, 96, 48, 3.0, true, "atrapado")
	Tiras.agregar(cuadros, ARTE_DESPIERTA, 96, 48, 6.0, false, "despierta")
	sprite_andres.sprite_frames = cuadros
	if cuadros.has_animation("atrapado"):
		sprite_andres.visible = true
		Tiras.ocultar_marcador(andres, sprite_andres)
		raiz_andres.visible = false
		sprite_andres.play("atrapado")


## Al terminar de sanar el árbol: "despierta" una vez y queda en el último cuadro
## (en el Acto 2 Andrés sigue así, quieto y sin alma).
func _despertar_andres() -> void:
	if not sprite_andres.sprite_frames.has_animation("despierta"):
		return
	sprite_andres.visible = true
	Tiras.ocultar_marcador(andres, sprite_andres)
	sprite_andres.play("despierta")
