extends AnimatableBody2D
## Plataforma que cae · 144x24 (3 casillas), capa 1 (mundo), se atraviesa desde abajo.
## Al pisarla tiembla 0,5 s y cae; a los 3 s de empezar a caer reaparece en su lugar.
## Si Lía muere, vuelve a su lugar.
## Origen = centro inferior de la casilla del medio; la pieza ocupa la mitad SUPERIOR.

const TIEMPO_TEMBLOR: float = 0.5
const TIEMPO_CAYENDO: float = 1.2        # luego se oculta
const TIEMPO_REAPARECER: float = 3.0     # contado desde que empieza a caer
const GRAVEDAD: float = 2200.0
const CAIDA_MAXIMA: float = 1000.0
const ANCHO: float = 144.0
const COLOR_MADERA: Color = Color(0.36, 0.23, 0.13)
const COLOR_RAIZ: Color = Color(0.22, 0.13, 0.07)

enum Estado { QUIETA, TEMBLANDO, CAYENDO, OCULTA }

@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual

var _estado: Estado = Estado.QUIETA
var _reloj: float = 0.0
var _velocidad: float = 0.0
var _inicio: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("reiniciables")
	_inicio = position
	_construir_visual()


func _physics_process(delta: float) -> void:
	match _estado:
		Estado.QUIETA:
			if _jugador_encima():
				_estado = Estado.TEMBLANDO
				_reloj = TIEMPO_TEMBLOR
		Estado.TEMBLANDO:
			_reloj -= delta
			visual.position.x = randf_range(-3.0, 3.0)
			if _reloj <= 0.0:
				visual.position.x = 0.0
				_estado = Estado.CAYENDO
				_reloj = 0.0
				_velocidad = 0.0
		Estado.CAYENDO:
			_reloj += delta
			_velocidad = minf(_velocidad + GRAVEDAD * delta, CAIDA_MAXIMA)
			position.y += _velocidad * delta
			visual.modulate.a = clampf(1.0 - (_reloj - 0.6) / (TIEMPO_CAYENDO - 0.6), 0.0, 1.0)
			if _reloj >= TIEMPO_CAYENDO:
				_estado = Estado.OCULTA
				colision.set_deferred("disabled", true)
				visual.visible = false
		Estado.OCULTA:
			_reloj += delta
			if _reloj >= TIEMPO_REAPARECER:
				reiniciar()
				visual.modulate.a = 0.0
				create_tween().tween_property(visual, "modulate:a", 1.0, 0.3)


## Vuelve a su lugar, quieta (al reaparecer o cuando Lía muere).
func reiniciar() -> void:
	_estado = Estado.QUIETA
	_reloj = 0.0
	_velocidad = 0.0
	position = _inicio
	colision.set_deferred("disabled", false)
	visual.position = Vector2.ZERO
	visual.visible = true
	visual.modulate.a = 1.0


## Lía está parada sobre esta plataforma.
func _jugador_encima() -> bool:
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador) or jugador.muerto or not jugador.is_on_floor():
		return false
	for i in range(jugador.get_slide_collision_count()):
		if jugador.get_slide_collision(i).get_collider() == self:
			return true
	return false


## Marcador 144x24: tabla de raíz café con vetas.
func _construir_visual() -> void:
	var tabla: ColorRect = ColorRect.new()
	tabla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tabla.color = COLOR_MADERA
	tabla.position = Vector2(-ANCHO / 2.0, -48.0)
	tabla.size = Vector2(ANCHO, 24.0)
	visual.add_child(tabla)
	for i in range(2):
		var veta: Line2D = Line2D.new()
		veta.width = 3.0
		veta.default_color = COLOR_RAIZ
		var x: float = -ANCHO / 2.0 + 4.0
		while x <= ANCHO / 2.0 - 4.0:
			veta.add_point(Vector2(x, -42.0 + i * 10.0 + sin(x * 0.08 + i * 2.0) * 3.0))
			x += 12.0
		visual.add_child(veta)
