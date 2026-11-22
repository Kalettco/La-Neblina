extends Area2D
## Esquirla de bruma: proyectil de la lanzadora (20 px, 420 px/s).
## Le quita 12 de luz a Lía. Choca con el mundo. El pulso del campo de luz la destruye.

const VELOCIDAD: float = 420.0
const DANO: float = 12.0
const VIDA_MAXIMA: float = 4.0
const COLOR_ESQUIRLA: Color = Color(0.45, 0.2, 0.6)

var direccion: Vector2 = Vector2.RIGHT
var _vida: float = 0.0
var _terminada: bool = false


func _ready() -> void:
	add_to_group("proyectiles_enemigos")
	$Visual.material = Efectos.material_sin_sombra()
	body_entered.connect(_al_tocar_cuerpo)


func _physics_process(delta: float) -> void:
	global_position += direccion * VELOCIDAD * delta
	$Visual.rotation += 8.0 * delta
	_vida += delta
	if _vida >= VIDA_MAXIMA:
		destruir()


func _al_tocar_cuerpo(cuerpo: Node2D) -> void:
	if _terminada:
		return
	if cuerpo is Jugador:
		(cuerpo as Jugador).recibir_dano(DANO, global_position.x)
	destruir()


## También la llama el campo de luz.
func destruir() -> void:
	if _terminada:
		return
	_terminada = true
	Efectos.estallido(get_parent(), global_position, COLOR_ESQUIRLA, 8)
	queue_free()
