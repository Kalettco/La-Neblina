extends Area2D
## Chispa de luz (disparo de Lía, clic derecho).
## Vuela recto hacia donde apuntó el mouse. Mientras vuela CUENTA COMO LUZ
## (radio 60 px): abre flores, sostiene plataformas de luz, carga braseros.
## Choca con el mundo (se apaga con chispas) y con enemigos (les hace daño).
## Con Shift (puntería asistida) sale hacia el enemigo más cercano al mouse y lo persigue.
## Al tocar un brasero lo carga de golpe (3 chispas lo encienden).

const RADIO_LUZ: float = 60.0
const COLOR_CHISPA: Color = Color(1.0, 0.92, 0.5)

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 1100.0
var alcance: float = 900.0
var dano: int = 1
## Puntería asistida (Shift): la chispa gira hacia este enemigo mientras vuela.
var objetivo: Node2D = null
const GIRO: float = 9.0                  # radianes por segundo

var _recorrido: float = 0.0
var _apagada: bool = false


func _ready() -> void:
	add_to_group("luces_extra")
	$Luz.texture = Efectos.textura_radial()
	$Luz.texture_scale = Efectos.escala_para_radio(90.0)
	$Visual.material = Efectos.material_sin_sombra()
	$Estela.material = Efectos.material_sin_sombra()
	area_entered.connect(_al_tocar_area)
	body_entered.connect(_al_tocar_cuerpo)


func _physics_process(delta: float) -> void:
	if _apagada:
		return
	if is_instance_valid(objetivo) and not objetivo.get("derrotado"):
		var deseada: Vector2 = (Vector2(objetivo.call("centro")) - global_position).normalized()
		var giro: float = clampf(direccion.angle_to(deseada), -GIRO * delta, GIRO * delta)
		direccion = direccion.rotated(giro)
	var paso: float = velocidad * delta
	global_position += direccion * paso
	_recorrido += paso
	if _recorrido >= alcance:
		_apagar()


## Las luces extra responden si un punto está iluminado por ellas.
func ilumina(punto: Vector2) -> bool:
	return not _apagada and global_position.distance_to(punto) <= RADIO_LUZ


func _al_tocar_area(area: Area2D) -> void:
	if _apagada:
		return
	if area.has_method("recibir_dano"):
		area.call("recibir_dano", dano, global_position)
		_apagar()
	elif area.has_method("recibir_chispa"):
		# Si devuelve false (ej. farol que no recarga), la chispa sigue de largo
		if area.call("recibir_chispa") != false:
			_apagar()


func _al_tocar_cuerpo(_cuerpo: Node2D) -> void:
	_apagar()


## Destello final y desaparece.
func _apagar() -> void:
	if _apagada:
		return
	_apagada = true
	remove_from_group("luces_extra")
	Efectos.estallido(get_parent(), global_position, COLOR_CHISPA, 10)
	queue_free()
