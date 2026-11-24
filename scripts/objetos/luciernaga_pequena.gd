class_name LuciernagaPequena
extends Area2D
## Luciérnaga pequeña: la sueltan los enemigos al ser destruidos.
## Recarga +5 de luz al tocarla. Si Lía está a menos de 150 px, vuela sola hacia ella.
## Origen = centro de la luciérnaga (24x24).

const RECARGA: float = 5.0
const RADIO_ATRACCION: float = 150.0
const VELOCIDAD_ATRACCION: float = 320.0
const VIDA_MAXIMA: float = 15.0          # si nadie la toma, se va volando
const COLOR_LUCIERNAGA: Color = Color(1.0, 0.92, 0.35)
const ARTE: String = "res://assets/sprites/luciernaga.png"   # cuadros de 24 x 24

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var luz: PointLight2D = $Luz

## Luz que recarga (las de las arenas recargan más).
var recarga: float = RECARGA

var _tiempo: float = 0.0
var _tomada: bool = false
var _x_anterior: float = 0.0


func _ready() -> void:
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(50.0)
	for hijo: Node in visual.get_children():
		(hijo as CanvasItem).material = Efectos.material_sin_sombra()
	if preparar_sprite(sprite):
		Tiras.ocultar_marcador(visual, sprite)
	body_entered.connect(_al_entrar_cuerpo)
	_tiempo = randf() * TAU
	_x_anterior = global_position.x


## Pone la animación "volar" en `destino` y la muestra. false si luciernaga.png no sirve.
## La usan también el frasco y otros efectos decorativos.
static func preparar_sprite(destino: AnimatedSprite2D) -> bool:
	var cuadros: SpriteFrames = Tiras.nuevas()
	if not Tiras.agregar(cuadros, ARTE, 24, 24, 10.0, true, "volar"):
		destino.visible = false
		return false
	destino.sprite_frames = cuadros
	destino.centered = true
	destino.visible = true
	destino.play("volar")
	destino.frame = randi() % cuadros.get_frame_count("volar")
	return true


func _physics_process(delta: float) -> void:
	_tiempo += delta
	visual.position.y = sin(_tiempo * 4.0) * 4.0
	_mirar_hacia_donde_va()
	if _tiempo > VIDA_MAXIMA + TAU:
		queue_free()
		return
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador) or jugador.muerto:
		return
	var destino: Vector2 = jugador.global_position + Vector2(0.0, -42.0)
	if global_position.distance_to(destino) < RADIO_ATRACCION:
		global_position = global_position.move_toward(destino, VELOCIDAD_ATRACCION * delta)


## Al moverse hacia la izquierda se voltea; quieta conserva la última dirección.
func _mirar_hacia_donde_va() -> void:
	var dx: float = global_position.x - _x_anterior
	_x_anterior = global_position.x
	if absf(dx) > 0.05:
		sprite.flip_h = dx < 0.0


func _al_entrar_cuerpo(cuerpo: Node2D) -> void:
	if _tomada or not cuerpo is Jugador or (cuerpo as Jugador).muerto:
		return
	_tomada = true
	(cuerpo as Jugador).recargar(recarga)
	Audio.sfx_frasco()
	Efectos.estallido(get_parent(), global_position, COLOR_LUCIERNAGA, 10)
	queue_free()
