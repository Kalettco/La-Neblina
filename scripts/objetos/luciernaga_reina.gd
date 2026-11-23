extends Area2D
## Luciérnaga Reina · 96x96. Al final del nivel 4 (El descenso).
## Si tiene id_arena, está oculta y aparece cuando esa arena se vence (el gólem).
## Al tocarla: luz llena y termina el nivel -> historia "La Luciérnaga Reina" -> campo de luz.
## Origen = centro inferior de la casilla; el cuerpo flota centrado en (0, -64).

const COLOR_REINA: Color = Color(1.0, 0.85, 0.4)
const ALTURA: float = -64.0

var id_arena: String = ""

@onready var visual: Node2D = $Visual
@onready var luz: PointLight2D = $Luz

var _aparecida: bool = false
var _tocada: bool = false
var _tiempo: float = 0.0
var _alas: Array[Polygon2D] = []


func _ready() -> void:
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(280.0)
	_construir_visual()
	if id_arena == "":
		_aparecida = true
	else:
		visual.modulate.a = 0.0
		luz.enabled = false


func _process(delta: float) -> void:
	_tiempo += delta
	visual.position.y = ALTURA + sin(_tiempo * 1.6) * 6.0
	luz.position.y = visual.position.y
	for i in range(_alas.size()):
		_alas[i].rotation = sin(_tiempo * 6.0) * 0.25 * (1.0 if i == 0 else -1.0)
	if not _aparecida:
		if _arena_vencida():
			_aparecer()
		return
	luz.energy = 1.3 + 0.2 * sin(_tiempo * 3.0)
	var jugador: Jugador = Juego.jugador
	if not _tocada and is_instance_valid(jugador) and not jugador.muerto and overlaps_body(jugador):
		_tocar(jugador)


func _arena_vencida() -> bool:
	for arena: Node in get_tree().get_nodes_in_group("arenas"):
		if arena.get("id_arena") == id_arena and arena.get("terminada"):
			return true
	return false


func _aparecer() -> void:
	_aparecida = true
	luz.enabled = true
	create_tween().tween_property(visual, "modulate:a", 1.0, 1.0)
	Efectos.estallido(get_parent(), global_position + Vector2(0.0, ALTURA), COLOR_REINA, 60)
	Juego.sacudir_camara(6.0, 0.4)
	Juego.toast("Algo enorme empezó a brillar en el fondo de la grieta.")


func _tocar(jugador: Jugador) -> void:
	_tocada = true
	jugador.recargar(jugador.energia_maxima)
	Audio.sfx_guardiana()
	Efectos.estallido(get_parent(), global_position + Vector2(0.0, ALTURA), COLOR_REINA, 80)
	Juego.sacudir_camara(8.0, 0.5)
	Juego.completar_nivel("La Luciérnaga Reina despertó.")


## Marcador 96x96: luciérnaga dorada enorme con alas claras y una corona de puntos.
func _construir_visual() -> void:
	for lado: float in [-1.0, 1.0]:
		var ala: Polygon2D = Polygon2D.new()
		ala.polygon = PackedVector2Array([
			Vector2(0.0, -8.0), Vector2(lado * 46.0, -40.0), Vector2(lado * 48.0, -6.0), Vector2(lado * 14.0, 8.0)])
		ala.color = Color(1.0, 0.97, 0.85, 0.55)
		ala.material = Efectos.material_sin_sombra()
		visual.add_child(ala)
		_alas.append(ala)
	var cuerpo: Polygon2D = Polygon2D.new()
	var puntos: PackedVector2Array = PackedVector2Array()
	for i in range(20):
		var angulo: float = TAU * i / 20.0
		puntos.append(Vector2(cos(angulo) * 20.0, sin(angulo) * 32.0))
	cuerpo.polygon = puntos
	cuerpo.color = COLOR_REINA
	cuerpo.material = Efectos.material_sin_sombra()
	visual.add_child(cuerpo)
	for i in range(3):
		var punto: ColorRect = ColorRect.new()
		punto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		punto.color = Color(1.0, 1.0, 0.8)
		punto.size = Vector2(6.0, 6.0)
		punto.position = Vector2(-15.0 + i * 12.0, -44.0 - (4.0 if i == 1 else 0.0))
		punto.material = Efectos.material_sin_sombra()
		visual.add_child(punto)
