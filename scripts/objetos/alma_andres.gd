extends Area2D
## Alma de Andrés · orbe dorado de 48 px. Aparece al vencer al Devorador de Luz.
## Al tocarla: historia FINAL -> pantalla final con estadísticas.
## Origen = centro inferior de la casilla; el orbe flota centrado en (0, -40).

const COLOR_ALMA: Color = Color(1.0, 0.85, 0.45)
const ALTURA: float = -40.0
const ARTE: String = "res://assets/sprites/alma_andres.png"   # cuadros de 48 x 48

@onready var visual: Node2D = $Visual
@onready var luz: PointLight2D = $Luz
@onready var sprite: AnimatedSprite2D = $Visual/Sprite

var _tiempo: float = 0.0
var _tocada: bool = false
var _anillo: Line2D = null


func _ready() -> void:
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(220.0)
	var orbe: Polygon2D = Polygon2D.new()
	var puntos: PackedVector2Array = PackedVector2Array()
	for i in range(20):
		var angulo: float = TAU * i / 20.0
		puntos.append(Vector2(cos(angulo), sin(angulo)) * 24.0)
	orbe.polygon = puntos
	orbe.color = COLOR_ALMA
	orbe.material = Efectos.material_sin_sombra()
	visual.add_child(orbe)
	_anillo = Line2D.new()
	_anillo.width = 3.0
	_anillo.default_color = Color(1.0, 0.95, 0.75, 0.8)
	_anillo.material = Efectos.material_sin_sombra()
	for i in range(25):
		var angulo: float = TAU * i / 24.0
		_anillo.add_point(Vector2(cos(angulo), sin(angulo)) * 34.0)
	visual.add_child(_anillo)
	_usar_arte()
	visual.modulate.a = 0.0
	create_tween().tween_property(visual, "modulate:a", 1.0, 1.0)


func _process(delta: float) -> void:
	_tiempo += delta
	visual.position.y = ALTURA + sin(_tiempo * 2.0) * 6.0
	luz.position.y = visual.position.y
	var pulso: float = 1.0 + 0.15 * sin(_tiempo * 4.0)
	_anillo.scale = Vector2(pulso, pulso)
	luz.energy = 1.3 + 0.25 * sin(_tiempo * 4.0)
	var jugador: Jugador = Juego.jugador
	if not _tocada and is_instance_valid(jugador) and not jugador.muerto and overlaps_body(jugador):
		_tocar(jugador)


func _tocar(jugador: Jugador) -> void:
	_tocada = true
	jugador.bloqueado = true
	jugador.invulnerable = 99.0
	Audio.sfx_guardiana()
	Efectos.estallido(get_parent(), global_position + Vector2(0.0, ALTURA), COLOR_ALMA, 80)
	Juego.toast("Lía guardó el alma de su papá en la linterna.")
	create_tween().tween_property(visual, "modulate:a", 0.0, 0.6)
	await get_tree().create_timer(1.5).timeout
	Juego.completar_juego()


## Si alma_andres.png sirve, se muestra el Sprite y se oculta el orbe de color.
func _usar_arte() -> void:
	var cuadros: SpriteFrames = Tiras.nuevas()
	if not Tiras.agregar(cuadros, ARTE, 48, 48, 8.0, true, "latir"):
		return
	sprite.sprite_frames = cuadros
	sprite.material = Efectos.material_sin_sombra()
	sprite.visible = true
	Tiras.ocultar_marcador(visual, sprite)
	sprite.play("latir")
