extends Area2D
## Luciérnaga guardiana (solo nivel 2, hay 3).
## Al tocarla: luz llena, guardianas +1, aviso y sacudida leve de cámara.
## Origen = centro inferior de la casilla.

const COLOR_GUARDIANA: Color = Color(0.45, 1.0, 0.85)
const ARTE: String = "res://assets/sprites/guardiana.png"   # cuadros de 48 x 48

@onready var nucleo: Node2D = $Visual
@onready var anillo: Line2D = $Visual/Anillo
@onready var luz: PointLight2D = $Luz
@onready var sprite: AnimatedSprite2D = $Visual/Sprite

var _tiempo: float = 0.0
var _rescatada: bool = false


func _ready() -> void:
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(130.0)
	for hijo: Node in nucleo.get_children():
		(hijo as CanvasItem).material = Efectos.material_sin_sombra()
	# Anillo circular de 20 px de radio alrededor del centro de la casilla
	for i in range(25):
		var angulo: float = TAU * i / 24.0
		anillo.add_point(Vector2(cos(angulo), sin(angulo)) * 20.0)
	_usar_arte()
	body_entered.connect(_al_entrar_cuerpo)


func _process(delta: float) -> void:
	# Flota y el anillo late
	_tiempo += delta
	nucleo.position.y = -24.0 + sin(_tiempo * 2.0) * 4.0
	var pulso: float = 1.0 + 0.12 * sin(_tiempo * 4.0)
	anillo.scale = Vector2(pulso, pulso)
	luz.energy = 1.1 + 0.2 * sin(_tiempo * 4.0)


func _al_entrar_cuerpo(cuerpo: Node2D) -> void:
	if _rescatada or not cuerpo is Jugador or (cuerpo as Jugador).muerto:
		return
	_rescatada = true
	var jugador: Jugador = cuerpo as Jugador
	jugador.recargar(jugador.energia_maxima)
	Juego.rescatar_guardiana()
	Juego.toast("Luciérnaga guardiana rescatada (%d/3). Tu luz está llena." % Juego.guardianas())
	Juego.sacudir_camara(6.0, 0.3)
	Audio.sfx_guardiana()
	Efectos.estallido(get_parent(), global_position + Vector2(0.0, -24.0), COLOR_GUARDIANA, 40)
	queue_free()


## Si guardiana.png sirve, se muestra el Sprite y se oculta el marcador de color.
func _usar_arte() -> void:
	var cuadros: SpriteFrames = Tiras.nuevas()
	if not Tiras.agregar(cuadros, ARTE, 48, 48, 8.0, true, "flotar"):
		return
	sprite.sprite_frames = cuadros
	sprite.visible = true
	Tiras.ocultar_marcador(nucleo, sprite)
	sprite.play("flotar")
