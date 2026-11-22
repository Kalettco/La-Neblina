class_name Farol
extends Area2D
## Farol de piedra = punto de control.
## Al tocarlo la primera vez se enciende y guarda el progreso.
## Si es el farol activo y Lía está cerca con poca luz, la recarga hasta 70.
## Origen = centro inferior de la casilla (pie del farol).

const RADIO_RECARGA: float = 180.0
const RECARGA_POR_SEGUNDO: float = 33.0
const LIMITE_RECARGA: float = 70.0
const COLOR_APAGADO: Color = Color(0.16, 0.16, 0.18)
const COLOR_ENCENDIDO: Color = Color(1.0, 0.6, 0.2)

@onready var cabeza: ColorRect = $Visual/Cabeza
@onready var luz: PointLight2D = $Luz

var encendido: bool = false     # ya se encendió alguna vez
var activo: bool = false        # es el punto de control actual


func _ready() -> void:
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(190.0)
	_aplicar_aspecto()
	body_entered.connect(_al_entrar_cuerpo)


func _physics_process(delta: float) -> void:
	if not activo:
		return
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return
	if jugador.global_position.distance_to(global_position) < RADIO_RECARGA:
		jugador.recargar_hasta(RECARGA_POR_SEGUNDO * delta, LIMITE_RECARGA)


func _al_entrar_cuerpo(cuerpo: Node2D) -> void:
	if encendido or not cuerpo is Jugador:
		return
	encendido = true
	activo = true
	_aplicar_aspecto()
	Juego.activar_farol(self)


## La llama Juego cuando se enciende otro farol.
func apagar() -> void:
	activo = false
	_aplicar_aspecto()


func _aplicar_aspecto() -> void:
	cabeza.color = COLOR_ENCENDIDO if activo else COLOR_APAGADO
	cabeza.material = Efectos.material_sin_sombra() if activo else null
	luz.enabled = activo
