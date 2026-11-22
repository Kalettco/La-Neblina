extends StaticBody2D
## Plataforma de luz: UNA pieza de 48 px. Solo existe mientras la linterna la ilumina.
## Al dejar de iluminarse aguanta "tiempo_gracia" (0,5 s; 1,5 s en la copa) y luego se desvanece.
## Origen = centro inferior de la casilla; la pieza ocupa la mitad SUPERIOR.

## Segundos que sigue sólida después de perder la luz (el nivel puede cambiarlo por zona).
@export var tiempo_gracia: float = 0.5
const TIEMPO_DESVANECER: float = 0.25
const PERIODO_DESTELLO: float = 2.5       # pista mientras está oculta
const DURACION_DESTELLO: float = 0.5
const ALFA_DESTELLO: float = 0.14
const CENTRO_Y: float = -36.0             # centro de la pieza (mitad superior de la casilla)
## Altura donde se mide la luz: justo bajo la SUPERFICIE de la pieza. Así la regla de
## los pies (60 px alrededor de la linterna) siempre alcanza la pieza donde está parada Lía.
const PUNTO_LUZ_Y: float = -46.0

@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual

var _sin_luz: float = 99.0                # segundos desde la última vez iluminada
var _existe: bool = true                  # se fuerza a false en _ready
var _reloj_destello: float = 0.0


func _ready() -> void:
	_reloj_destello = randf() * PERIODO_DESTELLO
	visual.modulate.a = 0.0
	_poner_existencia(false)


func _physics_process(delta: float) -> void:
	if _esta_iluminada():
		_sin_luz = 0.0
	else:
		_sin_luz += delta

	var debe_existir: bool = _sin_luz <= tiempo_gracia
	if debe_existir != _existe:
		_poner_existencia(debe_existir)
	_actualizar_aspecto(delta)


## Prueba 3 puntos: izquierda, centro y derecha de la pieza.
func _esta_iluminada() -> bool:
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return false
	for x: float in [-20.0, 0.0, 20.0]:
		if Juego.esta_iluminado(to_global(Vector2(x, PUNTO_LUZ_Y))):
			return true
	return false


func _poner_existencia(existe: bool) -> void:
	_existe = existe
	colision.set_deferred("disabled", not existe)


func _actualizar_aspecto(delta: float) -> void:
	if _existe:
		visual.modulate.a = 1.0
		return
	# Desvanecer y, ya oculta, un destello muy tenue cada 2,5 s
	_reloj_destello += delta
	if _reloj_destello >= PERIODO_DESTELLO:
		_reloj_destello -= PERIODO_DESTELLO
	var destello: float = 0.0
	if _reloj_destello < DURACION_DESTELLO:
		destello = sin(_reloj_destello / DURACION_DESTELLO * PI) * ALFA_DESTELLO
	var desvanecer: float = 1.0 - (_sin_luz - tiempo_gracia) / TIEMPO_DESVANECER
	visual.modulate.a = maxf(clampf(desvanecer, 0.0, 1.0), destello)
