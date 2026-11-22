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
const RUTA_ESCENA_NIVEL: String = "res://escenas/niveles/nivel.tscn"
const RUTA_TITULO: String = "res://escenas/ui/pantalla_titulo.tscn"
const RUTA_HISTORIA: String = "res://escenas/ui/pantalla_historia.tscn"
const RUTA_TARJETA: String = "res://escenas/ui/tarjeta_nivel.tscn"
const RUTA_FINAL: String = "res://escenas/ui/pantalla_final.tscn"
const RUTA_HABILIDAD: String = "res://escenas/ui/pantalla_habilidad.tscn"

## Niveles: 0 sendero · 1 bosque · 2 raíces · 3 descenso · 4 cavernas · 5 corazón
const NUM_NIVELES: int = 6
const NIVEL_CON_DISPARO: int = 2   # desde el nivel 3 se puede disparar
const NIVEL_CON_CAMPO: int = 4     # desde el nivel 5 se puede usar el campo de luz

# Historia que se está mostrando (la lee pantalla_historia)
var historia_paginas: Array = []
var historia_opciones: Dictionary = {}
var _historia_siguiente: Callable = Callable()

# Pantalla de habilidad nueva (la lee pantalla_habilidad)
var habilidad_titulo: String = ""
var habilidad_texto: String = ""
var _habilidad_siguiente: Callable = Callable()

# Habilidades del acto 2
var tiene_disparo: bool = false
var tiene_campo: bool = false

var nivel_actual: int = 0          # índice del nivel (ver NUM_NIVELES)
var estadisticas: Dictionary = {}
var jugador: Jugador = null
var nivel: Node = null
var zona_actual: String = ""
var en_cueva: bool = false         # las cazadoras van más rápido en la cueva
var limite_vacio: float = 1600.0   # si Lía cae más abajo de esta y, muere (lo ajusta el nivel)
var todas_asustadas: bool = false  # durante la entrega de luz final
var entregando_luz: bool = false   # la pantalla se oscurece casi por completo
var curando: bool = false          # el Árbol Madre está sanando: la oscuridad se aclara
var muriendo: bool = false
var nivel_terminado: bool = false

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
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	# F11: alterna pantalla completa / ventana (y lo guarda en la configuración)
	if event.keycode == KEY_F11:
		Configuracion.alternar_pantalla_completa()
	# F9 (solo durante el desarrollo): saltar al nivel siguiente para probarlo
	elif event.keycode == KEY_F9 and OS.is_debug_build():
		ir_a_nivel(mini(nivel_actual + 1, NUM_NIVELES - 1))


# --- Partida y estadísticas ---

## Título -> historia INTRO -> tarjeta del nivel 1.
func nueva_partida() -> void:
	nivel_actual = 0
	_reiniciar_estadisticas()
	mostrar_historia(Textos.INTRO, mostrar_tarjeta.bind(0))


## Título (Continuar) -> tarjeta del nivel elegido, con sus habilidades.
func continuar_partida(indice: int) -> void:
	_reiniciar_estadisticas()
	mostrar_tarjeta(clampi(indice, 0, cargar_progreso()))


## true si ya se jugó alguna vez (hay archivo de progreso).
func hay_partida_guardada() -> bool:
	return FileAccess.file_exists(RUTA_PROGRESO)


## Nombre de un nivel ("Nivel 3 · Las raíces profundas"), leído de su archivo de datos.
func nombre_nivel(indice: int) -> String:
	var datos: GDScript = Nivel.DATOS[clampi(indice, 0, Nivel.DATOS.size() - 1)]
	return String(datos.get_script_constant_map().get("NOMBRE", "Nivel %d" % (indice + 1)))


## Habilidades según el nivel: se ganan en orden, así que dependen del índice.
func _ajustar_habilidades(indice: int) -> void:
	tiene_disparo = indice >= NIVEL_CON_DISPARO
	tiene_campo = indice >= NIVEL_CON_CAMPO


func registrar_sombra_destruida() -> void:
	estadisticas["sombras_destruidas"] += 1


## Solo el campo de luz (los cristales no responden a la linterna normal).
func campo_ilumina(punto: Vector2) -> bool:
	return is_instance_valid(jugador) and jugador.campo_ilumina(punto)


func campo_activo() -> bool:
	return is_instance_valid(jugador) and jugador.campo_activo()


## Acto 2 (desde el nivel 3): los enemigos atacan y se pueden destruir.
func es_acto_2() -> bool:
	return nivel_actual >= NIVEL_CON_DISPARO


## ¿Hay luz en este punto? Cuenta la linterna de Lía, el campo de luz
## y cualquier luz extra (chispas en vuelo).
## Las luces extra están en el grupo "luces_extra" y tienen ilumina(punto) -> bool.
func esta_iluminado(punto: Vector2) -> bool:
	if is_instance_valid(jugador) and (jugador.esta_iluminado(punto) or jugador.campo_ilumina(punto)):
		return true
	for luz: Node in get_tree().get_nodes_in_group("luces_extra"):
		if luz.call("ilumina", punto):
			return true
	return false


# --- Flujo de pantallas ---

## Muestra páginas de historia; al terminar llama a "siguiente".
## opciones: {"linterna_apagada": [índices], "dorada": [índices]}
func mostrar_historia(paginas: Array, siguiente: Callable, opciones: Dictionary = {}) -> void:
	historia_paginas = paginas
	historia_opciones = opciones
	_historia_siguiente = siguiente
	_cambiar_escena(RUTA_HISTORIA)


## La llama pantalla_historia al pasar la última página.
func terminar_historia() -> void:
	if _historia_siguiente.is_valid():
		_historia_siguiente.call()


## Tarjeta con nombre y objetivo del nivel; Enter/clic empieza el nivel.
func mostrar_tarjeta(indice: int) -> void:
	nivel_actual = indice
	_cambiar_escena(RUTA_TARJETA)


## Pantalla "NUEVA HABILIDAD"; Enter/clic llama a "siguiente".
func mostrar_habilidad(titulo: String, texto: String, siguiente: Callable) -> void:
	habilidad_titulo = titulo
	habilidad_texto = texto
	_habilidad_siguiente = siguiente
	_cambiar_escena(RUTA_HABILIDAD)


func terminar_habilidad() -> void:
	if _habilidad_siguiente.is_valid():
		_habilidad_siguiente.call()


func ir_al_menu() -> void:
	_cambiar_escena(RUTA_TITULO)


func mostrar_pantalla_final() -> void:
	_cambiar_escena(RUTA_FINAL)


func _cambiar_escena(ruta: String) -> void:
	jugador = null
	muriendo = false
	Transicion.cambiar_escena(ruta)   # fundido a negro


## true si el evento es "Enter o clic" (para avanzar pantallas).
func es_avanzar(event: InputEvent) -> bool:
	if Transicion.ocupado():
		return false   # durante un fundido no se avanza (evita saltarse pantallas)
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventKey:
		return event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE)
	return false


## Tiempo en formato M:SS.
func tiempo_texto() -> String:
	var segundos: int = int(estadisticas["tiempo_juego"])
	return "%d:%02d" % [segundos / 60, segundos % 60]


func _reiniciar_estadisticas() -> void:
	estadisticas = {
		"tiempo_juego": 0.0,
		"muertes": 0,
		"luciernagas_liberadas": _lista_ceros(),
		"luciernagas_total": _lista_ceros(),
		"guardianas": 0,
		"sombras_destruidas": 0,
	}


func _lista_ceros() -> Array:
	var lista: Array = []
	lista.resize(NUM_NIVELES)
	lista.fill(0)
	return lista


## Lo llama cada frasco al aparecer, para saber cuántos hay en el nivel.
func registrar_frasco() -> void:
	estadisticas["luciernagas_total"][nivel_actual] += 1
	_avisar_luciernagas()


func liberar_luciernaga() -> void:
	estadisticas["luciernagas_liberadas"][nivel_actual] += 1
	_avisar_luciernagas()


## Un frasco reapareció porque Lía murió antes de llegar a otro farol.
func devolver_luciernaga() -> void:
	estadisticas["luciernagas_liberadas"][nivel_actual] -= 1
	_avisar_luciernagas()


func _avisar_luciernagas() -> void:
	luciernagas_cambiadas.emit(
		estadisticas["luciernagas_liberadas"][nivel_actual],
		estadisticas["luciernagas_total"][nivel_actual])


func luciernagas_liberadas() -> int:
	return estadisticas["luciernagas_liberadas"][nivel_actual]


func luciernagas_total() -> int:
	return estadisticas["luciernagas_total"][nivel_actual]


## La llama el constructor de niveles al empezar (o reiniciar) un nivel.
func iniciar_nivel(nuevo_nivel: Node) -> void:
	nivel = nuevo_nivel
	estadisticas["luciernagas_liberadas"][nivel_actual] = 0
	estadisticas["luciernagas_total"][nivel_actual] = 0
	if nivel_actual == 1:
		estadisticas["guardianas"] = 0
		guardianas_cambiadas.emit(0)
	zona_actual = ""
	en_cueva = false
	todas_asustadas = false
	entregando_luz = false
	curando = false
	nivel_terminado = false
	_cartel_forzado = ""
	_texto_cartel_mostrado = ""


## Carga el nivel i (ver NUM_NIVELES) con el constructor de niveles.
func ir_a_nivel(indice: int) -> void:
	nivel_actual = indice
	_ajustar_habilidades(indice)
	guardar_progreso()
	_cambiar_escena(RUTA_ESCENA_NIVEL)


## Lía llegó a la salida de un nivel: lo que sigue depende del nivel.
func completar_nivel() -> void:
	if nivel_terminado:
		return
	nivel_terminado = true
	# Lía se queda quieta en la salida: no puede caerse ni recibir daño
	if is_instance_valid(jugador):
		jugador.bloqueado = true
		jugador.invulnerable = 99.0
	toast("Llegaste al final del sendero." if nivel_actual == 0 else "Llegaste a la salida.")
	await get_tree().create_timer(1.5).timeout
	var siguiente: int = nivel_actual + 1
	# Se guarda ya el nivel siguiente, por si el jugador cierra durante la historia
	_guardar_nivel_alcanzado(siguiente)
	match nivel_actual:
		0:   # sendero -> historia PUENTE -> bosque
			mostrar_historia(Textos.PUENTE, mostrar_tarjeta.bind(siguiente))
		3:   # descenso -> Luciérnaga Reina -> campo de luz -> cavernas
			mostrar_historia(Textos.REINA, mostrar_habilidad.bind(
				Textos.HABILIDAD_CAMPO_TITULO, Textos.HABILIDAD_CAMPO_TEXTO, mostrar_tarjeta.bind(siguiente)))
		4:   # cavernas -> "Antes del corazón" -> corazón
			mostrar_historia(Textos.ANTES_CORAZON, mostrar_tarjeta.bind(siguiente))
		5:   # corazón (jefe) -> final del juego
			completar_juego()
		_:   # sin historia entre niveles
			mostrar_tarjeta(siguiente)


func rescatar_guardiana() -> void:
	estadisticas["guardianas"] += 1
	guardianas_cambiadas.emit(estadisticas["guardianas"])


func guardianas() -> int:
	return estadisticas["guardianas"]


## El Árbol Madre sanó (fin del nivel 2): "El árbol habla" -> disparo de luz -> nivel 3.
func completar_arbol() -> void:
	if nivel_terminado:
		return
	nivel_terminado = true
	_guardar_nivel_alcanzado(NIVEL_CON_DISPARO)
	await get_tree().create_timer(1.0).timeout
	mostrar_historia(Textos.ARBOL_HABLA, mostrar_habilidad.bind(
		Textos.HABILIDAD_DISPARO_TITULO, Textos.HABILIDAD_DISPARO_TEXTO,
		mostrar_tarjeta.bind(NIVEL_CON_DISPARO)), Textos.OPCIONES_ARBOL_HABLA)


## Fin del juego (alma de Andrés): historia FINAL -> pantalla final con estadísticas.
func completar_juego() -> void:
	nivel_terminado = true
	mostrar_historia(Textos.FINAL, mostrar_pantalla_final, Textos.OPCIONES_FINAL)


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
	# Lo liberado hasta aquí queda guardado
	for frasco: Node in get_tree().get_nodes_in_group("frascos"):
		frasco.call("confirmar")
	toast("Farol encendido: progreso guardado.")
	Audio.sfx_farol()


func obtener_punto_reaparicion() -> Vector2:
	return punto_control if hay_punto_control else punto_inicio


## Lía se desmaya, la pantalla se oscurece con el mensaje y vuelve al último farol.
func morir(mensaje: String) -> void:
	# Con el nivel ya terminado (salida o Árbol Madre) no se puede morir
	if muriendo or nivel_terminado or not is_instance_valid(jugador):
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
	for enemigo: Node in get_tree().get_nodes_in_group("enemigos"):
		enemigo.call("reiniciar")
	# Los proyectiles enemigos en vuelo desaparecen
	for proyectil: Node in get_tree().get_nodes_in_group("proyectiles_enemigos"):
		proyectil.queue_free()
	# Los frascos agarrados después del último farol vuelven a aparecer
	for frasco: Node in get_tree().get_nodes_in_group("frascos"):
		frasco.call("restaurar")


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

## Guarda el nivel actual como alcanzado (y las habilidades).
func guardar_progreso() -> void:
	_guardar_nivel_alcanzado(nivel_actual)


## Guarda el nivel más alto alcanzado y las habilidades que corresponden.
func _guardar_nivel_alcanzado(indice: int) -> void:
	var archivo: ConfigFile = ConfigFile.new()
	archivo.load(RUTA_PROGRESO)   # si no existe, se crea nuevo
	var maximo: int = clampi(maxi(int(archivo.get_value("progreso", "nivel_maximo", 0)), indice), 0, NUM_NIVELES - 1)
	archivo.set_value("progreso", "nivel_maximo", maximo)
	archivo.set_value("progreso", "tiene_disparo", maximo >= NIVEL_CON_DISPARO)
	archivo.set_value("progreso", "tiene_campo", maximo >= NIVEL_CON_CAMPO)
	archivo.save(RUTA_PROGRESO)


## Devuelve el índice del nivel más alto alcanzado (0 si nunca se jugó).
func cargar_progreso() -> int:
	var archivo: ConfigFile = ConfigFile.new()
	if archivo.load(RUTA_PROGRESO) != OK:
		return 0
	return clampi(int(archivo.get_value("progreso", "nivel_maximo", 0)), 0, NUM_NIVELES - 1)
