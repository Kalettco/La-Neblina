extends Node
## Autoload "Juego": estado global de la partida.
## Guarda estadísticas, punto de control, referencias al jugador y avisa al HUD con señales.

signal energia_cambiada(energia: float, maxima: float)
signal luciernagas_cambiadas(liberadas: int, total: int)
signal guardianas_cambiadas(cantidad: int)
signal zona_cambiada(nombre: String)
signal toast_pedido(texto: String)
signal cartel_cambiado(texto: String, es_nota: bool)   # texto vacío = ocultar

const RUTA_PROGRESO: String = "user://progreso.cfg"
const DISTANCIA_CARTEL_X: float = 2.5 * 48.0
const DISTANCIA_CARTEL_Y: float = 3.0 * 48.0
const DURACION_MUERTE: float = 1.5
const ESCENA_MUERTE: PackedScene = preload("res://escenas/ui/pantalla_muerte.tscn")

var nivel_actual: int = 0          # 0 = tutorial, 1 = bosque
var estadisticas: Dictionary = {}
var jugador: Jugador = null
var nivel: Node = null
var zona_actual: String = ""
var en_cueva: bool = false         # las cazadoras van más rápido en la cueva
var limite_vacio: float = 1600.0   # si Lía cae más abajo de esta y, muere (lo ajusta el nivel)
var todas_asustadas: bool = false  # durante la entrega de luz final
var muriendo: bool = false

# Punto de control
var punto_inicio: Vector2 = Vector2.ZERO
var punto_control: Vector2 = Vector2.ZERO
var hay_punto_control: bool = false
var farol_activo: Farol = null

# Carteles
var _cartel_forzado: String = ""    # texto que pone un objeto (ej. Árbol Madre)
var _cartel_forzado_es_nota: bool = false
var _texto_cartel_mostrado: String = ""


func _ready() -> void:
	# Sigue funcionando en pausa (para F11)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reiniciar_estadisticas()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if is_instance_valid(jugador):
		estadisticas["tiempo_juego"] += delta
	_actualizar_cartel()


func _unhandled_input(event: InputEvent) -> void:
	# F11: alterna pantalla completa / ventana
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# --- Partida y estadísticas ---

func nueva_partida() -> void:
	nivel_actual = 0
	_reiniciar_estadisticas()


func _reiniciar_estadisticas() -> void:
	estadisticas = {
		"tiempo_juego": 0.0,
		"muertes": 0,
		"luciernagas_liberadas": [0, 0],
		"luciernagas_total": [0, 0],
		"guardianas": 0,
	}


## Lo llama cada frasco al aparecer, para saber cuántos hay en el nivel.
func registrar_frasco() -> void:
	estadisticas["luciernagas_total"][nivel_actual] += 1
	_avisar_luciernagas()


func liberar_luciernaga() -> void:
	estadisticas["luciernagas_liberadas"][nivel_actual] += 1
	_avisar_luciernagas()


func _avisar_luciernagas() -> void:
	luciernagas_cambiadas.emit(
		estadisticas["luciernagas_liberadas"][nivel_actual],
		estadisticas["luciernagas_total"][nivel_actual])


func luciernagas_liberadas() -> int:
	return estadisticas["luciernagas_liberadas"][nivel_actual]


func luciernagas_total() -> int:
	return estadisticas["luciernagas_total"][nivel_actual]


func cambiar_zona(nombre: String) -> void:
	if nombre == zona_actual:
		return
	zona_actual = nombre
	zona_cambiada.emit(nombre)


# --- Jugador, punto de control, muerte ---

func registrar_jugador(nuevo_jugador: Jugador) -> void:
	jugador = nuevo_jugador
	punto_inicio = nuevo_jugador.global_position
	hay_punto_control = false
	farol_activo = null
	muriendo = false
	todas_asustadas = false


func activar_farol(farol: Farol) -> void:
	if is_instance_valid(farol_activo) and farol_activo != farol:
		farol_activo.apagar()
	farol_activo = farol
	punto_control = farol.global_position
	hay_punto_control = true
	toast("Farol encendido: progreso guardado.")
	Audio.sfx_farol()


func obtener_punto_reaparicion() -> Vector2:
	return punto_control if hay_punto_control else punto_inicio


## Lía se desmaya, la pantalla se oscurece con el mensaje y vuelve al último farol.
func morir(mensaje: String) -> void:
	if muriendo or not is_instance_valid(jugador):
		return
	muriendo = true
	estadisticas["muertes"] += 1
	jugador.desmayar()
	Audio.sfx_muerte()
	var pantalla: PantallaMuerte = ESCENA_MUERTE.instantiate()
	get_tree().root.add_child(pantalla)
	pantalla.mostrar(mensaje)
	await get_tree().create_timer(DURACION_MUERTE).timeout
	reaparecer()
	if is_instance_valid(pantalla):
		pantalla.ocultar()
	muriendo = false


func reaparecer() -> void:
	if is_instance_valid(jugador):
		jugador.reaparecer(obtener_punto_reaparicion())
	for sombra: Node in get_tree().get_nodes_in_group("sombras"):
		sombra.call("reiniciar")


func sacudir_camara(fuerza: float, duracion: float) -> void:
	if is_instance_valid(jugador):
		jugador.sacudir(fuerza, duracion)


# --- Mensajes en pantalla ---

func toast(texto: String) -> void:
	toast_pedido.emit(texto)


## Fuerza un texto en el recuadro de carteles. Texto vacío = vuelve a lo normal.
func mostrar_cartel(texto: String, es_nota: bool) -> void:
	_cartel_forzado = texto
	_cartel_forzado_es_nota = es_nota


## Busca el cartel más cercano a Lía y avisa al HUD si cambió.
func _actualizar_cartel() -> void:
	var texto: String = ""
	var es_nota: bool = false
	if _cartel_forzado != "":
		texto = _cartel_forzado
		es_nota = _cartel_forzado_es_nota
	elif is_instance_valid(jugador):
		var mejor_distancia: float = INF
		for cartel: Node in get_tree().get_nodes_in_group("carteles"):
			var c: Node2D = cartel as Node2D
			var diferencia: Vector2 = (c.global_position - jugador.global_position).abs()
			if diferencia.x < DISTANCIA_CARTEL_X and diferencia.y < DISTANCIA_CARTEL_Y:
				var distancia: float = diferencia.length()
				if distancia < mejor_distancia:
					mejor_distancia = distancia
					texto = c.get("texto")
					es_nota = c.get("es_nota")
	if texto != _texto_cartel_mostrado:
		_texto_cartel_mostrado = texto
		cartel_cambiado.emit(texto, es_nota)


# --- Guardado ---

func guardar_progreso() -> void:
	var archivo: ConfigFile = ConfigFile.new()
	archivo.load(RUTA_PROGRESO)   # si no existe, se crea nuevo
	var maximo: int = maxi(int(archivo.get_value("progreso", "nivel_maximo", 0)), nivel_actual)
	archivo.set_value("progreso", "nivel_maximo", maximo)
	archivo.save(RUTA_PROGRESO)


## Devuelve el nivel más alto alcanzado (0 si nunca se jugó).
func cargar_progreso() -> int:
	var archivo: ConfigFile = ConfigFile.new()
	if archivo.load(RUTA_PROGRESO) != OK:
		return 0
	return int(archivo.get_value("progreso", "nivel_maximo", 0))
