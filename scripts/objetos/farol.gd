class_name Farol
extends Area2D
## Farol de piedra = punto de control.
## Al tocarlo la primera vez se enciende y guarda el progreso.
## Si es el farol activo y Lía está cerca con poca luz, la recarga hasta 70.
## Con clic derecho cerca del farol activo, la luz se llena hasta 100.
## Acto 2: si una chispa golpea un farol ya encendido (aunque esté lejos), le devuelve
## +20 de luz a Lía (un golpe por segundo por farol). Sirve en las arenas, disparando
## al farol de la entrada a través de la puerta de raíces.
## Origen = centro inferior de la casilla (pie del farol).

const RADIO_RECARGA: float = 180.0
const RECARGA_POR_SEGUNDO: float = 33.0
const LIMITE_RECARGA: float = 70.0
const RECARGA_MANUAL_POR_SEGUNDO: float = 120.0   # clic derecho: se llena en menos de 1 s
const COLOR_APAGADO: Color = Color(0.16, 0.16, 0.18)
const COLOR_ENCENDIDO: Color = Color(1.0, 0.6, 0.2)
const RECARGA_CHISPA: float = 20.0
const ESPERA_CHISPA: float = 1.0
const COLOR_LUZ: Color = Color(1.0, 0.86, 0.55)

var _espera_chispa: float = 0.0

@onready var cabeza: ColorRect = $Visual/Cabeza
@onready var luz: PointLight2D = $Luz

var encendido: bool = false     # ya se encendió alguna vez
var activo: bool = false        # es el punto de control actual
var _recarga_manual: bool = false


func _ready() -> void:
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(190.0)
	_aplicar_aspecto()
	body_entered.connect(_al_entrar_cuerpo)


## Una chispa golpeó el farol: si ya estaba encendido, devuelve luz a Lía.
## Devuelve true si se quedó con la chispa; false si la deja pasar (farol apagado,
## en espera, o Lía está al lado: así no le "roba" los disparos al pelear junto a él).
func recibir_chispa() -> bool:
	var jugador: Jugador = Juego.jugador
	if not encendido or _espera_chispa > 0.0 or not is_instance_valid(jugador) or jugador.muerto:
		return false
	if jugador.global_position.distance_to(global_position) < RADIO_RECARGA:
		return false
	_espera_chispa = ESPERA_CHISPA
	jugador.recargar(RECARGA_CHISPA)
	Audio.sfx_farol()
	Efectos.estallido(get_parent(), global_position + Vector2(0.0, -110.0), COLOR_LUZ, 18)
	Efectos.estallido(jugador.get_parent(), jugador.global_position + Vector2(0.0, -42.0), COLOR_LUZ, 14)
	Juego.toast("El farol te devolvió luz (+%d)." % int(RECARGA_CHISPA))
	luz.enabled = true
	luz.energy = 2.0
	create_tween().tween_property(luz, "energy", 1.0, 0.4).finished.connect(_aplicar_aspecto)
	return true


func _physics_process(delta: float) -> void:
	_espera_chispa = maxf(_espera_chispa - delta, 0.0)
	if not activo:
		return
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return
	var cerca: bool = not jugador.muerto \
			and jugador.global_position.distance_to(global_position) < RADIO_RECARGA
	if not cerca:
		_recarga_manual = false
		return
	jugador.recargar_hasta(RECARGA_POR_SEGUNDO * delta, LIMITE_RECARGA)

	# Clic derecho cerca del farol activo: llena la luz hasta el máximo
	if Input.is_action_just_pressed("recargar_luz") and jugador.energia < jugador.energia_maxima:
		_recarga_manual = true
		Juego.toast("El farol recarga tu luz.")
		Audio.sfx_farol()
	if _recarga_manual:
		jugador.recargar(RECARGA_MANUAL_POR_SEGUNDO * delta)
		luz.energy = 1.0 + 0.4 * sin(Time.get_ticks_msec() * 0.02)   # el farol late mientras recarga
		if jugador.energia >= jugador.energia_maxima:
			_recarga_manual = false
			luz.energy = 1.0


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
