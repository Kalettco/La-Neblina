extends Control
## Pantalla de título: bosque oscuro con luciérnagas flotando.
## Menú: Nuevo juego · Continuar (nivel 2, si ya se llegó) · Configuración · Salir.
## Funciona con el mouse y con el teclado (flechas + Enter).

const ANCHO: float = 1920.0
const ALTO: float = 1080.0
const ESCENA_CONFIGURACION: PackedScene = preload("res://escenas/ui/pantalla_configuracion.tscn")

@onready var bosque: Control = $Bosque
@onready var boton_nuevo: Button = $Menu/Caja/Botones/Nuevo
@onready var boton_continuar: Button = $Menu/Caja/Botones/Continuar
@onready var boton_configuracion: Button = $Menu/Caja/Botones/Configuracion
@onready var boton_salir: Button = $Menu/Caja/Botones/Salir


func _ready() -> void:
	boton_continuar.disabled = not Juego.hay_partida_guardada()
	boton_nuevo.pressed.connect(_al_nuevo)
	boton_continuar.pressed.connect(_al_continuar)
	boton_configuracion.pressed.connect(_al_configurar)
	boton_salir.pressed.connect(_al_salir)
	_crear_bosque()
	boton_nuevo.grab_focus()
	Audio.musica("titulo")


func _al_nuevo() -> void:
	_bloquear_botones()
	Juego.nueva_partida()


func _al_continuar() -> void:
	_bloquear_botones()
	Juego.continuar_partida()


func _al_configurar() -> void:
	var configuracion: Node = ESCENA_CONFIGURACION.instantiate()
	configuracion.cerrado.connect(boton_configuracion.grab_focus)
	add_child(configuracion)


func _al_salir() -> void:
	get_tree().quit()


## Evita que un doble clic dispare dos veces el cambio de escena.
func _bloquear_botones() -> void:
	for boton: Button in [boton_nuevo, boton_continuar, boton_configuracion, boton_salir]:
		boton.disabled = true


## Dos capas de siluetas de árboles y una franja de neblina.
func _crear_bosque() -> void:
	var azar: RandomNumberGenerator = RandomNumberGenerator.new()
	azar.seed = 77
	_capa_arboles(azar, Color("0c1a1d"), 380.0, 720.0, 80.0)
	var neblina: ColorRect = ColorRect.new()
	neblina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	neblina.color = Color(Color("96aca6"), 0.07)
	neblina.position = Vector2(0.0, ALTO - 420.0)
	neblina.size = Vector2(ANCHO, 200.0)
	bosque.add_child(neblina)
	_capa_arboles(azar, Color("091416"), 220.0, 460.0, 120.0)


func _capa_arboles(azar: RandomNumberGenerator, color: Color, alto_min: float, alto_max: float, separacion: float) -> void:
	var x: float = -40.0
	while x < ANCHO + 80.0:
		var alto_arbol: float = azar.randf_range(alto_min, alto_max)
		var medio_ancho: float = azar.randf_range(40.0, 95.0)
		var arbol: Polygon2D = Polygon2D.new()
		arbol.color = color
		arbol.polygon = PackedVector2Array([
			Vector2(x - medio_ancho, ALTO),
			Vector2(x, ALTO - alto_arbol),
			Vector2(x + medio_ancho, ALTO),
		])
		bosque.add_child(arbol)
		x += separacion * azar.randf_range(0.6, 1.4)
