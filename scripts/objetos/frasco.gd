extends Area2D
## Frasco con luciérnaga: al tocarlo libera la luciérnaga y recarga +30 de luz.
## Si Lía muere antes de encender otro farol, el frasco vuelve a aparecer
## (lo agarrado después del último farol no queda guardado).
## Origen = centro inferior de la casilla.

const RECARGA: float = 30.0
const COLOR_LUCIERNAGA: Color = Color(1.0, 0.92, 0.35)

@onready var visual: Node2D = $Visual
@onready var luciernaga: ColorRect = $Visual/Luciernaga
@onready var luz: PointLight2D = $Luz

var _tiempo: float = 0.0
var _altura_base: float = 0.0
var _liberado: bool = false
var _guardado: bool = false      # liberado ANTES del farol activo: ya no vuelve


func _ready() -> void:
	add_to_group("frascos")
	luz.texture = Efectos.textura_radial()
	luz.texture_scale = Efectos.escala_para_radio(70.0)
	luciernaga.material = Efectos.material_sin_sombra()
	_altura_base = luciernaga.position.y
	_tiempo = randf() * TAU   # cada frasco flota a destiempo
	body_entered.connect(_al_entrar_cuerpo)
	Juego.registrar_frasco()


func _process(delta: float) -> void:
	# La luciérnaga flota +-3 px
	_tiempo += delta
	luciernaga.position.y = _altura_base + sin(_tiempo * 3.0) * 3.0
	luz.energy = 0.8 + 0.15 * sin(_tiempo * 5.0)


func _al_entrar_cuerpo(cuerpo: Node2D) -> void:
	if _liberado or not cuerpo is Jugador or (cuerpo as Jugador).muerto:
		return
	_liberado = true
	(cuerpo as Jugador).recargar(RECARGA)
	Juego.liberar_luciernaga()
	Juego.toast("Liberaste una luciérnaga: +30 de luz.")
	Audio.sfx_frasco()
	Efectos.estallido(get_parent(), global_position + Vector2(0.0, -20.0), COLOR_LUCIERNAGA)
	_mostrar(false)


## Lo llama Juego al encender un farol: lo ya liberado queda guardado.
func confirmar() -> void:
	if _liberado:
		_guardado = true


## Lo llama Juego cuando Lía reaparece: vuelve si no estaba guardado.
func restaurar() -> void:
	if not _liberado or _guardado:
		return
	_liberado = false
	Juego.devolver_luciernaga()
	_mostrar(true)


func _mostrar(visible_ahora: bool) -> void:
	visual.visible = visible_ahora
	luz.enabled = visible_ahora
