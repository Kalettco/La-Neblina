extends Area2D
## Brasero: si la linterna lo ilumina sin parar, se carga (1 por segundo).
## Si deja de iluminarse, la carga baja 0,6 por segundo.
## Al llegar a 1 se enciende y abre todas las puertas de raíces de su grupo.
## Origen = centro inferior de la casilla.

const VELOCIDAD_CARGA: float = 1.0
const VELOCIDAD_DESCARGA: float = 0.6
const ANCHO_BARRA: float = 48.0
const COLOR_APAGADO: Color = Color(0.4, 0.4, 0.42)
const COLOR_ENCENDIDO: Color = Color(1.0, 0.5, 0.15)

@export var grupo: String = "a"

@onready var cuenco: ColorRect = $Visual/Cuenco
@onready var barra: ColorRect = $Visual/Barra
@onready var luz: PointLight2D = $Luz

var carga: float = 0.0
var encendido: bool = false


func _ready() -> void:
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(200.0)
	barra.material = Efectos.material_sin_sombra()
	_aplicar_aspecto()


func _physics_process(delta: float) -> void:
	if encendido:
		luz.energy = 1.0 + 0.12 * sin(Time.get_ticks_msec() * 0.012)   # la llama tiembla
		return
	var jugador: Jugador = Juego.jugador
	var iluminado: bool = is_instance_valid(jugador) and (
		jugador.esta_iluminado(global_position + Vector2(0.0, -80.0))
		or jugador.esta_iluminado(global_position + Vector2(0.0, -48.0)))
	if iluminado:
		carga = minf(carga + VELOCIDAD_CARGA * delta, 1.0)
	else:
		carga = maxf(carga - VELOCIDAD_DESCARGA * delta, 0.0)
	if carga >= 1.0:
		_encender()
	_aplicar_aspecto()


func _encender() -> void:
	encendido = true
	for puerta: Node in get_tree().get_nodes_in_group("puertas"):
		if puerta.get("grupo") == grupo:
			puerta.call("abrir")
	Juego.sacudir_camara(10.0, 0.4)
	Juego.toast("El brasero se encendió. Las raíces se abrieron.")
	Audio.sfx_puerta()


func _aplicar_aspecto() -> void:
	cuenco.color = COLOR_ENCENDIDO if encendido else COLOR_APAGADO
	cuenco.material = Efectos.material_sin_sombra() if encendido else null
	luz.enabled = encendido
	barra.visible = not encendido and carga > 0.0
	barra.size.x = ANCHO_BARRA * carga
