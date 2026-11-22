extends Area2D
## Flor trampolín: se abre 1,6 s al iluminarla (se renueva mientras siga iluminada).
## Si Lía la toca cayendo (o caminando) mientras está abierta, sale disparada hacia arriba.
## Origen = centro inferior de la casilla.

const TIEMPO_ABIERTA: float = 1.6
const FUERZA_REBOTE: float = -1455.0      # unas 8,5 casillas de altura
const ESPERA_REBOTE: float = 0.25         # evita rebotes dobles
const COLOR_REBOTE: Color = Color(1.0, 0.55, 0.8)

@onready var capullo: ColorRect = $Visual/Capullo
@onready var petalos: Node2D = $Visual/Petalos
@onready var luz: PointLight2D = $Luz

var _abierta: float = 0.0
var _espera: float = 0.0


func _ready() -> void:
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(90.0)
	for petalo: Node in petalos.get_children():
		(petalo as CanvasItem).material = Efectos.material_sin_sombra()
	_aplicar_aspecto()


func _physics_process(delta: float) -> void:
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return
	if Juego.esta_iluminado(global_position + Vector2(0.0, -24.0)):
		_abierta = TIEMPO_ABIERTA
	else:
		_abierta = maxf(_abierta - delta, 0.0)
	_espera = maxf(_espera - delta, 0.0)
	_aplicar_aspecto()

	if _abierta > 0.0 and _espera <= 0.0 and not jugador.muerto \
			and jugador.velocity.y >= 0.0 and overlaps_body(jugador):
		_rebotar(jugador)


func _rebotar(jugador: Jugador) -> void:
	_espera = ESPERA_REBOTE
	jugador.impulsar(FUERZA_REBOTE)
	Audio.sfx_rebote()
	Efectos.estallido(get_parent(), global_position + Vector2(0.0, -24.0), COLOR_REBOTE, 18)


func _aplicar_aspecto() -> void:
	var abierta: bool = _abierta > 0.0
	capullo.visible = not abierta
	petalos.visible = abierta
	luz.enabled = abierta
