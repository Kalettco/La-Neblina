extends Node
## Autoload "Audio": todavía no hay sonidos.
## El juego ya llama estas funciones en los momentos correctos;
## cuando lleguen los archivos de audio solo hay que llenarlas.
##
## Buses de audio (se crean solos si no existen):
##   "Musica"   -> la música (usar bus = "Musica" en los AudioStreamPlayer de música)
##   "Ambiente" -> sonidos de ambiente y efectos (bus = "Ambiente")
## La configuración (Configuracion.modo_sonido) silencia cada bus.

const BUS_MUSICA: String = "Musica"
const BUS_AMBIENTE: String = "Ambiente"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_bus(BUS_MUSICA)
	_crear_bus(BUS_AMBIENTE)


func _crear_bus(nombre: String) -> void:
	if AudioServer.get_bus_index(nombre) != -1:
		return
	AudioServer.add_bus()
	var indice: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(indice, nombre)
	AudioServer.set_bus_send(indice, "Master")


## Enciende o silencia la música y el sonido de ambiente.
func configurar(musica_encendida: bool, ambiente_encendido: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MUSICA), not musica_encendida)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_AMBIENTE), not ambiente_encendido)


func sfx_salto() -> void:
	pass


func sfx_frasco() -> void:
	pass


func sfx_guardiana() -> void:
	pass


func sfx_dano() -> void:
	pass


func sfx_farol() -> void:
	pass


func sfx_puerta() -> void:
	pass


func sfx_muerte() -> void:
	pass


func sfx_rebote() -> void:
	pass


func sfx_curacion() -> void:
	pass


# --- Acto 2 ---

func sfx_disparo() -> void:
	pass


func sfx_impacto() -> void:
	pass


func sfx_enemigo_muere() -> void:
	pass


func sfx_campo() -> void:
	pass


func sfx_esquirla() -> void:
	pass


func sfx_golem_golpe() -> void:
	pass


func sfx_jefe_ataque() -> void:
	pass


func sfx_jefe_muere() -> void:
	pass


## Nombres usados: "titulo", "jefe".
func musica(_nombre: String) -> void:
	pass
