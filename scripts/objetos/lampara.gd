extends Node2D
## Lámpara de luciérnagas (arena del jefe final): mientras Lía está cerca, le recarga
## la luz rápido hasta el máximo. No es punto de control (para eso están los faroles).
## Origen = centro inferior de la casilla (pie de la lámpara).

const RADIO: float = 130.0
const RECARGA_POR_SEGUNDO: float = 45.0
const COLOR_LAMPARA: Color = Color(1.0, 0.85, 0.4)
const ALTO: float = 80.0

var _tiempo: float = 0.0
var _luz: PointLight2D = null
var _vidrio: ColorRect = null
var _reloj_chispas: float = 0.0


func _ready() -> void:
	var poste: ColorRect = ColorRect.new()
	poste.mouse_filter = Control.MOUSE_FILTER_IGNORE
	poste.color = Color(0.25, 0.2, 0.16)
	poste.position = Vector2(-4.0, -ALTO + 20.0)
	poste.size = Vector2(8.0, ALTO - 20.0)
	add_child(poste)
	_vidrio = ColorRect.new()
	_vidrio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vidrio.color = COLOR_LAMPARA
	_vidrio.position = Vector2(-12.0, -ALTO - 6.0)
	_vidrio.size = Vector2(24.0, 28.0)
	_vidrio.material = Efectos.material_sin_sombra()
	add_child(_vidrio)
	var techo: ColorRect = ColorRect.new()
	techo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	techo.color = Color(0.25, 0.2, 0.16)
	techo.position = Vector2(-16.0, -ALTO - 12.0)
	techo.size = Vector2(32.0, 6.0)
	add_child(techo)
	_luz = PointLight2D.new()
	_luz.texture = Efectos.textura_radial()
	_luz.texture_scale = Efectos.escala_para_radio(170.0)
	_luz.color = COLOR_LAMPARA
	_luz.energy = 1.0
	_luz.position = Vector2(0.0, -ALTO + 8.0)
	add_child(_luz)


func _physics_process(delta: float) -> void:
	_tiempo += delta
	var jugador: Jugador = Juego.jugador
	var recargando: bool = is_instance_valid(jugador) and not jugador.muerto \
			and jugador.energia < jugador.energia_maxima \
			and (jugador.global_position + Vector2(0.0, -42.0)).distance_to(global_position + Vector2(0.0, -ALTO / 2.0)) < RADIO
	if recargando:
		jugador.recargar(RECARGA_POR_SEGUNDO * delta)
		_luz.energy = 1.4 + 0.4 * sin(_tiempo * 14.0)   # late mientras recarga
		_reloj_chispas -= delta
		if _reloj_chispas <= 0.0:
			_reloj_chispas = 0.25
			Efectos.estallido(get_parent(), jugador.global_position + Vector2(0.0, -42.0), COLOR_LAMPARA, 6)
	else:
		_luz.energy = 1.0 + 0.1 * sin(_tiempo * 3.0)
