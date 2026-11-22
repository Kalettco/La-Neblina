extends Area2D
## Luciérnaga pequeña: la sueltan los enemigos al ser destruidos.
## Recarga +5 de luz al tocarla. Si Lía está a menos de 150 px, vuela sola hacia ella.
## Origen = centro de la luciérnaga (24x24).

const RECARGA: float = 5.0
const RADIO_ATRACCION: float = 150.0
const VELOCIDAD_ATRACCION: float = 320.0
const VIDA_MAXIMA: float = 15.0          # si nadie la toma, se va volando
const COLOR_LUCIERNAGA: Color = Color(1.0, 0.92, 0.35)

@onready var visual: Node2D = $Visual
@onready var luz: PointLight2D = $Luz

var _tiempo: float = 0.0
var _tomada: bool = false


func _ready() -> void:
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(50.0)
	for hijo: Node in visual.get_children():
		(hijo as CanvasItem).material = Efectos.material_sin_sombra()
	body_entered.connect(_al_entrar_cuerpo)
	_tiempo = randf() * TAU


func _physics_process(delta: float) -> void:
	_tiempo += delta
	visual.position.y = sin(_tiempo * 4.0) * 4.0
	if _tiempo > VIDA_MAXIMA + TAU:
		queue_free()
		return
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador) or jugador.muerto:
		return
	var destino: Vector2 = jugador.global_position + Vector2(0.0, -42.0)
	if global_position.distance_to(destino) < RADIO_ATRACCION:
		global_position = global_position.move_toward(destino, VELOCIDAD_ATRACCION * delta)


func _al_entrar_cuerpo(cuerpo: Node2D) -> void:
	if _tomada or not cuerpo is Jugador or (cuerpo as Jugador).muerto:
		return
	_tomada = true
	(cuerpo as Jugador).recargar(RECARGA)
	Audio.sfx_frasco()
	Efectos.estallido(get_parent(), global_position, COLOR_LUCIERNAGA, 10)
	queue_free()
