class_name Nivel
extends Node2D
## Constructor genérico de niveles.
## Lee un archivo de datos (scripts/datos/...) que llama a los COMANDOS de abajo
## con coordenadas en CASILLAS (x = columna, y = fila, fila 0 arriba).
##
## Origen de los objetos: centro inferior de su casilla ((x + 0,5) * 48, (y + 1) * 48).
## Agua, espinas y puertas: esquina superior izquierda de su primera casilla.

const CASILLA: float = 48.0

## Cuando llegue el arte, poner aquí el TileSet real (terrenos 3x3 de 13 piezas).
## Si el archivo no existe, se genera un TileSet provisional por código.
const RUTA_TILESET: String = "res://assets/tilesets/tileset_neblina.tres"

## Datos de cada nivel, en orden (Juego.nivel_actual elige cuál).
const DATOS: Array[GDScript] = [
	preload("res://scripts/datos/nivel_1_sendero.gd"),
	preload("res://scripts/datos/nivel_2_bosque.gd"),
	preload("res://scripts/datos/nivel_3_raices.gd"),
	preload("res://scripts/datos/nivel_4_descenso.gd"),
	preload("res://scripts/datos/nivel_5_cavernas.gd"),
	preload("res://scripts/datos/nivel_6_corazon.gd"),
]

const ESCENA_JUGADOR: PackedScene = preload("res://escenas/jugador/jugador.tscn")
const ESCENA_HUD: PackedScene = preload("res://escenas/ui/hud.tscn")
const ESCENA_PAUSA: PackedScene = preload("res://escenas/ui/pausa.tscn")
const ESCENA_FRASCO: PackedScene = preload("res://escenas/objetos/frasco.tscn")
const ESCENA_FAROL: PackedScene = preload("res://escenas/objetos/farol.tscn")
const ESCENA_FLOR: PackedScene = preload("res://escenas/objetos/flor.tscn")
const ESCENA_BRASERO: PackedScene = preload("res://escenas/objetos/brasero.tscn")
const ESCENA_PUERTA: PackedScene = preload("res://escenas/objetos/puerta_raices.tscn")
const ESCENA_PLATAFORMA: PackedScene = preload("res://escenas/objetos/plataforma_luz.tscn")
const ESCENA_CARTEL: PackedScene = preload("res://escenas/objetos/cartel.tscn")
const ESCENA_PELIGRO: PackedScene = preload("res://escenas/objetos/peligro.tscn")
const ESCENA_SALIDA: PackedScene = preload("res://escenas/objetos/salida.tscn")
const ESCENA_SOMBRA: PackedScene = preload("res://escenas/enemigos/sombra.tscn")
const ESCENA_LANZADORA: PackedScene = preload("res://escenas/enemigos/lanzadora.tscn")
const ESCENA_CRISTAL: PackedScene = preload("res://escenas/objetos/cristal.tscn")
const ESCENA_PUERTA_ARENA: PackedScene = preload("res://escenas/objetos/puerta_arena.tscn")
const ESCENA_ARENA: PackedScene = preload("res://escenas/objetos/arena.tscn")
const ESCENA_GUARDIANA: PackedScene = preload("res://escenas/objetos/guardiana.tscn")
const ESCENA_ARBOL: PackedScene = preload("res://escenas/objetos/arbol_madre.tscn")

# Terrenos del TileSet provisional (columna del atlas)
const TERRENO_BOSQUE: int = 0
const TERRENO_CUEVA: int = 1
const TERRENO_COPA: int = 2
const FILA_SUPERFICIE: int = 0   # casilla con borde de pasto/roca arriba
const FILA_INTERIOR: int = 1

# Oscuridad de la zona -> color del CanvasModulate
const COLORES_OSCURIDAD: Dictionary = {
	0.62: Color("3a4560"),   # luz de luna (inicio del tutorial)
	0.80: Color("1a2238"),   # bosque de noche
	0.85: Color("151b2e"),
	0.88: Color("100f16"),   # cueva
}
const COLOR_ENTREGA: Color = Color("050508")
const COLOR_CURACION: Color = Color("7d8aa6")   # la oscuridad se aclara al sanar el árbol
const COLOR_CAMPO: Color = Color("9aa6c8")      # tono claro mientras dura el campo de luz
const COLOR_FONDO_CUEVA: Color = Color("17130f")
const VELOCIDAD_COLOR: float = 6.0     # el color de la noche cambia en ~0,5 s
const MULTIPLICADOR_GRACIA_COPA: float = 3.0   # plataformas de luz en la copa: 0,5 s x 3
const EXTRA_ABAJO: float = 240.0       # roca de relleno visible bajo el nivel (deja sitio al cartel)

## Solo para escenas de PRUEBA: si se pone un archivo de datos aquí, se usa ese
## en vez del nivel actual, y se juega como acto 2 (con disparo).
@export var datos_prueba: GDScript = null

var ancho: int = 0
var alto: int = 0
var datos: GDScript = null
var zonas: Array[Dictionary] = []
var jugador: Jugador = null

var _inicio: Vector2i = Vector2i.ZERO
var _celdas_solidas: Dictionary = {}   # Vector2i -> true

@onready var noche: CanvasModulate = $Noche
@onready var fondo: Node2D = $Fondo
@onready var terreno: TileMapLayer = $Terreno
@onready var objetos: Node2D = $Objetos
@onready var enemigos: Node2D = $Enemigos


func _ready() -> void:
	if datos_prueba != null:
		datos = datos_prueba
		Juego.nivel_actual = Juego.NIVEL_CON_DISPARO
		Juego.tiene_disparo = true
		Juego.tiene_campo = true
	else:
		datos = DATOS[clampi(Juego.nivel_actual, 0, DATOS.size() - 1)]
	Juego.iniciar_nivel(self)
	datos.construir(self)
	_pintar_terreno()
	_crear_bordes()
	_crear_fondo()
	_crear_jugador()
	add_child(ESCENA_HUD.instantiate())
	add_child(ESCENA_PAUSA.instantiate())
	Juego.limite_vacio = alto * CASILLA + 200.0
	_actualizar_zona(1.0)


func _process(delta: float) -> void:
	_actualizar_zona(delta)


# =============================================================================
# COMANDOS (los llaman los archivos de datos)
# =============================================================================

func tamano(nuevo_ancho: int, nuevo_alto: int) -> void:
	ancho = nuevo_ancho
	alto = nuevo_alto


func inicio(x: int, y: int) -> void:
	_inicio = Vector2i(x, y)


## Zona horizontal [x0, x1): nombre en el HUD, oscuridad y si es cueva.
func zona(x0: int, x1: int, nombre: String, oscuridad: float, es_cueva: bool) -> void:
	zonas.append({"x0": x0, "x1": x1, "nombre": nombre, "oscuridad": oscuridad, "es_cueva": es_cueva})


## Rellena con roca desde la fila y hasta el fondo (x0 y x1 incluidos).
func suelo(x0: int, x1: int, y: int) -> void:
	bloque(x0, x1, y, alto - 1)


## Rectángulo sólido (todos los extremos incluidos).
func bloque(x0: int, x1: int, y0: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			_celdas_solidas[Vector2i(x, y)] = true


## En la copa de los árboles las piezas aguantan 3 veces más sin luz (saltos más largos).
func plataforma_luz(x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1 + 1):
		var pieza: Node2D = ESCENA_PLATAFORMA.instantiate()
		if _terreno_de_columna(x) == TERRENO_COPA:
			pieza.set("tiempo_gracia", 0.5 * MULTIPLICADOR_GRACIA_COPA)
		_colocar(pieza, x, y, objetos)


func agua(x0: int, x1: int, y: int) -> void:
	_peligro("agua", x0, x1, y)


func espinas(x0: int, x1: int, y: int) -> void:
	_peligro("espinas", x0, x1, y)


func frasco(x: int, y: int) -> void:
	_colocar(ESCENA_FRASCO.instantiate(), x, y, objetos)


func farol(x: int, y: int) -> void:
	_colocar(ESCENA_FAROL.instantiate(), x, y, objetos)


func flor(x: int, y: int) -> void:
	_colocar(ESCENA_FLOR.instantiate(), x, y, objetos)


func brasero(x: int, y: int, grupo: String) -> void:
	var nuevo: Node2D = ESCENA_BRASERO.instantiate()
	nuevo.set("grupo", grupo)
	_colocar(nuevo, x, y, objetos)


## Puerta de 1 casilla de ancho, de la fila y0 a la y1 (incluidas).
func puerta(x: int, y0: int, y1: int, grupo: String) -> void:
	var nueva: Node2D = ESCENA_PUERTA.instantiate()
	nueva.set("grupo", grupo)
	nueva.set("alto_casillas", y1 - y0 + 1)
	nueva.position = Vector2(x * CASILLA, y0 * CASILLA)
	objetos.add_child(nueva)


func cartel(x: int, y: int, texto: String) -> void:
	_cartel(x, y, texto, false)


func nota(x: int, y: int, texto: String) -> void:
	_cartel(x, y, texto, true)


## Sombra de la Bruma. x0 y x1 son los límites de su recorrido (casillas).
func sombra(tipo: String, x: int, y: int, x0: int, x1: int) -> void:
	var nueva: Node2D = ESCENA_SOMBRA.instantiate()
	nueva.set("tipo", tipo)
	nueva.set("limite_izq", (x0 + 0.5) * CASILLA)
	nueva.set("limite_der", (x1 + 0.5) * CASILLA)
	_colocar(nueva, x, y, enemigos)


func salida(x: int, y: int) -> void:
	_colocar(ESCENA_SALIDA.instantiate(), x, y, objetos)


func guardiana(x: int, y: int) -> void:
	_colocar(ESCENA_GUARDIANA.instantiate(), x, y, objetos)


func arbol(x: int, y: int) -> void:
	_colocar(ESCENA_ARBOL.instantiate(), x, y, objetos)


## Lanzadora de bruma (acto 2): flota en la casilla (x, y).
func lanzadora(x: int, y: int) -> void:
	_colocar(ESCENA_LANZADORA.instantiate(), x, y, enemigos)


# =============================================================================
# CONSTRUCCIÓN
# =============================================================================

## Posición en píxeles del centro inferior de una casilla.
static func pie_de_casilla(x: int, y: int) -> Vector2:
	return Vector2((x + 0.5) * CASILLA, (y + 1) * CASILLA)


func _colocar(nodo: Node2D, x: int, y: int, contenedor: Node2D) -> void:
	nodo.position = pie_de_casilla(x, y)
	contenedor.add_child(nodo)


func _peligro(tipo: String, x0: int, x1: int, y: int) -> void:
	var nuevo: Node2D = ESCENA_PELIGRO.instantiate()
	nuevo.set("tipo", tipo)
	nuevo.set("ancho_casillas", x1 - x0 + 1)
	nuevo.position = Vector2(x0 * CASILLA, y * CASILLA)
	objetos.add_child(nuevo)


func _cartel(x: int, y: int, texto: String, es_nota: bool) -> void:
	var nuevo: Node2D = ESCENA_CARTEL.instantiate()
	nuevo.set("texto", texto)
	nuevo.set("es_nota", es_nota)
	_colocar(nuevo, x, y, objetos)


## Paredes invisibles a la izquierda y derecha del nivel: Lía no puede salirse del mapa.
func _crear_bordes() -> void:
	var bordes: StaticBody2D = StaticBody2D.new()
	bordes.name = "Bordes"
	bordes.collision_layer = 1   # mundo
	bordes.collision_mask = 0
	var alto_pared: float = alto * CASILLA + 2400.0
	for x: float in [-CASILLA / 2.0, ancho * CASILLA + CASILLA / 2.0]:
		var forma: RectangleShape2D = RectangleShape2D.new()
		forma.size = Vector2(CASILLA, alto_pared)
		var colision: CollisionShape2D = CollisionShape2D.new()
		colision.shape = forma
		colision.position = Vector2(x, alto * CASILLA - alto_pared / 2.0 + 400.0)
		bordes.add_child(colision)
	add_child(bordes)


func _crear_jugador() -> void:
	jugador = ESCENA_JUGADOR.instantiate()
	jugador.position = pie_de_casilla(_inicio.x, _inicio.y)
	add_child(jugador)
	# Límites de la cámara = tamaño del nivel.
	# Abajo se dejan EXTRA_ABAJO px de roca de relleno para que el recuadro de carteles
	# no tape el suelo. Si el nivel es más bajo que la pantalla, arriba se ve cielo.
	var camara: Camera2D = jugador.camara
	var fondo_camara: int = int(alto * CASILLA + EXTRA_ABAJO)
	camara.limit_left = 0
	camara.limit_right = int(ancho * CASILLA)
	camara.limit_bottom = fondo_camara
	camara.limit_top = mini(0, fondo_camara - 1080)
	camara.reset_smoothing()


func zona_en(x_casilla: int) -> Dictionary:
	for z: Dictionary in zonas:
		if x_casilla >= z["x0"] and x_casilla < z["x1"]:
			return z
	return zonas[0] if not zonas.is_empty() else {}


func _actualizar_zona(delta: float) -> void:
	if not is_instance_valid(jugador):
		return
	var z: Dictionary = zona_en(int(floor(jugador.global_position.x / CASILLA)))
	if z.is_empty():
		return
	Juego.cambiar_zona(z["nombre"])
	Juego.en_cueva = z["es_cueva"]
	var objetivo: Color = _color_de_oscuridad(z["oscuridad"])
	if Juego.curando:
		objetivo = COLOR_CURACION
	elif Juego.entregando_luz:
		objetivo = COLOR_ENTREGA
	elif Juego.campo_activo():
		objetivo = COLOR_CAMPO
	noche.color = noche.color.lerp(objetivo, minf(1.0, VELOCIDAD_COLOR * delta))


func _color_de_oscuridad(oscuridad: float) -> Color:
	var mejor: float = 0.80
	for clave: float in COLORES_OSCURIDAD.keys():
		if absf(clave - oscuridad) < absf(mejor - oscuridad):
			mejor = clave
	return COLORES_OSCURIDAD[mejor]


func _terreno_de_columna(x: int) -> int:
	var z: Dictionary = zona_en(x)
	if z.is_empty():
		return TERRENO_BOSQUE
	if z["es_cueva"]:
		return TERRENO_CUEVA
	if String(z["nombre"]).to_lower().contains("copa"):
		return TERRENO_COPA
	return TERRENO_BOSQUE


func _pintar_terreno() -> void:
	terreno.tile_set = _obtener_tileset()
	for celda: Vector2i in _celdas_solidas.keys():
		var arriba_solida: bool = _celdas_solidas.has(celda + Vector2i.UP)
		var fila: int = FILA_INTERIOR if arriba_solida else FILA_SUPERFICIE
		terreno.set_cell(celda, 0, Vector2i(_terreno_de_columna(celda.x), fila))
	# Relleno bajo el nivel (solo decorado): continúa las columnas que llegan al fondo
	var filas_extra: int = int(ceil(EXTRA_ABAJO / CASILLA)) + 1
	for x in range(ancho):
		if _celdas_solidas.has(Vector2i(x, alto - 1)):
			for y in range(alto, alto + filas_extra):
				terreno.set_cell(Vector2i(x, y), 0, Vector2i(_terreno_de_columna(x), FILA_INTERIOR))


func _obtener_tileset() -> TileSet:
	if ResourceLoader.exists(RUTA_TILESET):
		return load(RUTA_TILESET)
	return _crear_tileset_provisional()


## Atlas 144x96: 3 terrenos (bosque, cueva, copa) x 2 filas (superficie, interior).
func _crear_tileset_provisional() -> TileSet:
	var tam: int = int(CASILLA)
	var rellenos: Array[Color] = [Color("1b2a22"), Color("272220"), Color("4a3624")]
	var bordes: Array[Color] = [Color("2f5a3a"), Color("3d352f"), Color("5e4630")]
	var imagen: Image = Image.create(tam * 3, tam * 2, false, Image.FORMAT_RGBA8)
	for t in range(3):
		for fila in range(2):
			var rect: Rect2i = Rect2i(t * tam, fila * tam, tam, tam)
			imagen.fill_rect(rect, rellenos[t])
			# Un poco de textura para que se note la cuadrícula del mundo
			imagen.fill_rect(Rect2i(rect.position + Vector2i(0, tam - 2), Vector2i(tam, 2)), rellenos[t].darkened(0.15))
			if fila == FILA_SUPERFICIE:
				imagen.fill_rect(Rect2i(rect.position, Vector2i(tam, 10)), bordes[t])

	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(tam, tam)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)   # capa 1: mundo
	tileset.set_physics_layer_collision_mask(0, 0)

	var fuente: TileSetAtlasSource = TileSetAtlasSource.new()
	fuente.texture = ImageTexture.create_from_image(imagen)
	fuente.texture_region_size = Vector2i(tam, tam)
	tileset.add_source(fuente, 0)
	var mitad: float = CASILLA / 2.0
	var cuadrado: PackedVector2Array = PackedVector2Array([
		Vector2(-mitad, -mitad), Vector2(mitad, -mitad), Vector2(mitad, mitad), Vector2(-mitad, mitad)])
	for t in range(3):
		for fila in range(2):
			var coords: Vector2i = Vector2i(t, fila)
			fuente.create_tile(coords)
			var datos_casilla: TileData = fuente.get_tile_data(coords, 0)
			datos_casilla.add_collision_polygon(0)
			datos_casilla.set_collision_polygon_points(0, 0, cuadrado)
	return tileset


## Fondo provisional: siluetas de árboles en 2 capas con parallax y una franja de neblina.
## En las zonas de cueva se pone un fondo de roca detrás del terreno.
func _crear_fondo() -> void:
	var piso: float = alto * CASILLA
	var azar: RandomNumberGenerator = RandomNumberGenerator.new()
	azar.seed = 1234
	_capa_parallax(0.2, _siluetas(azar, Color("0c1a1d"), piso, 380.0, 700.0, 70.0))
	_capa_parallax(0.45, _siluetas(azar, Color("091416"), piso, 220.0, 480.0, 110.0))
	var neblina: ColorRect = ColorRect.new()
	neblina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	neblina.color = Color(Color("96aca6"), 0.07)
	neblina.position = Vector2(0.0, piso - 520.0)
	neblina.size = Vector2(1920.0, 220.0)
	_capa_parallax(0.6, [neblina])

	for z: Dictionary in zonas:
		if z["es_cueva"]:
			var roca: ColorRect = ColorRect.new()
			roca.mouse_filter = Control.MOUSE_FILTER_IGNORE
			roca.color = COLOR_FONDO_CUEVA
			roca.position = Vector2(z["x0"] * CASILLA, -1080.0)
			roca.size = Vector2((z["x1"] - z["x0"]) * CASILLA, piso + 1080.0)
			fondo.add_child(roca)


func _capa_parallax(desplazamiento: float, hijos: Array) -> void:
	var capa: Parallax2D = Parallax2D.new()
	capa.scroll_scale = Vector2(desplazamiento, 1.0)
	capa.repeat_size = Vector2(1920.0, 0.0)
	capa.repeat_times = 3
	for hijo: Node in hijos:
		capa.add_child(hijo)
	fondo.add_child(capa)


## Árboles triangulares a lo ancho de 1920 px (se repite).
func _siluetas(azar: RandomNumberGenerator, color: Color, piso: float,
		alto_min: float, alto_max: float, separacion: float) -> Array:
	var resultado: Array = []
	var x: float = 0.0
	while x < 1920.0:
		var alto_arbol: float = azar.randf_range(alto_min, alto_max)
		var medio_ancho: float = azar.randf_range(40.0, 90.0)
		var arbol: Polygon2D = Polygon2D.new()
		arbol.color = color
		arbol.polygon = PackedVector2Array([
			Vector2(x - medio_ancho, piso),
			Vector2(x, piso - alto_arbol),
			Vector2(x + medio_ancho, piso),
		])
		resultado.append(arbol)
		x += separacion * azar.randf_range(0.6, 1.4)
	return resultado


## Plataforma de cristal (una pieza por casilla): solo aparece con el CAMPO de luz.
func cristal(x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1 + 1):
		_colocar(ESCENA_CRISTAL.instantiate(), x, y, objetos)


## Raíz que habla: textos de la voz del Árbol Madre (acto 2).
func nota_raiz(x: int, y: int, texto: String) -> void:
	var nuevo: Node2D = ESCENA_CARTEL.instantiate()
	nuevo.set("texto", texto)
	nuevo.set("es_raiz", true)
	_colocar(nuevo, x, y, objetos)


## Puerta de arena de 1 casilla de ancho, filas y0..y1. "cerrada" = salida de la arena.
func puerta_arena(x: int, y0: int, y1: int, id: String, cerrada: bool = false) -> void:
	var nueva: Node2D = ESCENA_PUERTA_ARENA.instantiate()
	nueva.set("id_arena", id)
	nueva.set("cerrada_al_inicio", cerrada)
	nueva.set("alto_casillas", y1 - y0 + 1)
	nueva.position = Vector2(x * CASILLA, y0 * CASILLA)
	objetos.add_child(nueva)


## Arena de oleadas entre las columnas x0 y x1 (ver formato en scripts/objetos/arena.gd).
func arena(x0: int, x1: int, id: String, oleadas: Array) -> void:
	var nueva: Node2D = ESCENA_ARENA.instantiate()
	nueva.set("id_arena", id)
	nueva.set("x0", x0)
	nueva.set("x1", x1)
	nueva.set("oleadas", oleadas)
	enemigos.add_child(nueva)
