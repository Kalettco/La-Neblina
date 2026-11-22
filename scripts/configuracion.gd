extends Node
## Autoload "Configuracion": pantalla y sonido elegidos por el jugador.
## Se guarda en user://configuracion.cfg y se aplica al abrir el juego.

const RUTA: String = "user://configuracion.cfg"

## Tamaños de ventana (según la pantalla de cada jugador).
const TAMANOS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const NOMBRES_TAMANO: Array[String] = ["Pequeña (1280 x 720)", "Mediana (1600 x 900)", "Grande (1920 x 1080)"]

## Modos de sonido: [música encendida, ambiente encendido]
const MODOS_SONIDO: Array[String] = ["Música y ambiente", "Solo música", "Solo ambiente", "Silencio"]
const MODOS_SONIDO_VALORES: Array = [[true, true], [true, false], [false, true], [false, false]]

var pantalla_completa: bool = false
var tamano: int = 0
var modo_sonido: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cargar()
	# Se aplica al terminar de arrancar (la ventana ya existe)
	aplicar.call_deferred()


func aplicar() -> void:
	aplicar_pantalla()
	aplicar_sonido()


func aplicar_pantalla() -> void:
	if pantalla_completa:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Tamaño elegido, sin pasarse del área útil del monitor, y centrada
	var monitor: int = DisplayServer.window_get_current_screen()
	var area: Rect2i = DisplayServer.screen_get_usable_rect(monitor)
	var medida: Vector2i = TAMANOS[tamano]
	medida = Vector2i(mini(medida.x, area.size.x), mini(medida.y, area.size.y))
	DisplayServer.window_set_size(medida)
	DisplayServer.window_set_position(area.position + (area.size - medida) / 2)


func aplicar_sonido() -> void:
	var valores: Array = MODOS_SONIDO_VALORES[modo_sonido]
	Audio.configurar(valores[0], valores[1])


func alternar_pantalla_completa() -> void:
	pantalla_completa = not pantalla_completa
	aplicar_pantalla()
	guardar()


func siguiente_tamano() -> void:
	tamano = (tamano + 1) % TAMANOS.size()
	aplicar_pantalla()
	guardar()


func siguiente_modo_sonido() -> void:
	modo_sonido = (modo_sonido + 1) % MODOS_SONIDO.size()
	aplicar_sonido()
	guardar()


func guardar() -> void:
	var archivo: ConfigFile = ConfigFile.new()
	archivo.set_value("pantalla", "completa", pantalla_completa)
	archivo.set_value("pantalla", "tamano", tamano)
	archivo.set_value("sonido", "modo", modo_sonido)
	archivo.save(RUTA)


func cargar() -> void:
	var archivo: ConfigFile = ConfigFile.new()
	if archivo.load(RUTA) != OK:
		# Primera vez: el juego EXPORTADO arranca en pantalla completa;
		# al probar desde el editor (F5) arranca en ventana.
		pantalla_completa = not OS.is_debug_build()
		return
	pantalla_completa = bool(archivo.get_value("pantalla", "completa", false))
	tamano = clampi(int(archivo.get_value("pantalla", "tamano", 0)), 0, TAMANOS.size() - 1)
	modo_sonido = clampi(int(archivo.get_value("sonido", "modo", 0)), 0, MODOS_SONIDO.size() - 1)
