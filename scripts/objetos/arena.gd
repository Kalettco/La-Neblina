extends Node2D
## Arena de oleadas.
## Cuando Lía entra (pasa la columna x0), se cierran las puertas de arena de su id,
## aparecen los enemigos de la oleada 1; al vencerlos, la siguiente; al vencer la
## última se abren todas las puertas de ese id.
## Si Lía muere, la arena vuelve a empezar (puertas como al inicio, enemigos fuera).
##
## Formato de "oleadas" (en casillas), una lista por oleada:
##   ["sombra", "patrulla" | "cazadora", x, y]
##   ["lanzadora", x, y]
##   ["murcielagos", x, y, cantidad]
##   ["golem", x, y]           (camina dentro de toda la arena)
##   ["golem", x, y, x0, x1]   (camina solo entre las columnas x0 y x1)
##   ["frasco", x, y]          (aparece al empezar esa oleada)
## En niveles verticales, y0..y1 son las filas donde puede empezar.
## Si luciernagas_cada > 0, mientras dura la pelea aparecen luciérnagas sueltas
## (cada ese número de segundos, hasta MAX_LUCIERNAGAS a la vez) que recargan luz.

const ESCENA_SOMBRA: PackedScene = preload("res://escenas/enemigos/sombra.tscn")
const ESCENA_LANZADORA: PackedScene = preload("res://escenas/enemigos/lanzadora.tscn")
const ESCENA_FRASCO: PackedScene = preload("res://escenas/objetos/frasco.tscn")
const ESCENA_LUCIERNAGA: PackedScene = preload("res://escenas/objetos/luciernaga_pequena.tscn")
const ESPERA_ENTRE_OLEADAS: float = 1.2
const COLOR_APARECER: Color = Color(0.4, 0.2, 0.55)
const COLOR_LUCIERNAGA: Color = Color(1.0, 0.92, 0.35)
const MAX_LUCIERNAGAS: int = 3
const RECARGA_LUCIERNAGA: float = 12.0
const FILAS_LUCIERNAGAS: int = 9      # aparecen en las 9 filas de más abajo de la arena

var id_arena: String = "arena"
var x0: int = 0                      # columnas (casillas) de la arena
var x1: int = 0
var y0: int = -100000                # filas donde puede empezar
var y1: int = 100000
var oleadas: Array = []
var luciernagas_cada: float = 0.0     # segundos entre luciérnagas (0 = ninguna)

var _reloj_luciernaga: float = 0.0
var _luciernagas: Array = []

var empezada: bool = false
var terminada: bool = false
var _oleada: int = -1
var _vivos: Array = []
var _extras: Array = []              # frascos que aparecieron en la arena
var _esperando: float = 0.0


func _ready() -> void:
	add_to_group("arenas")


func _physics_process(delta: float) -> void:
	if terminada:
		return
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador) or jugador.muerto:
		return
	if not empezada:
		var columna: int = int(floor(jugador.global_position.x / Nivel.CASILLA))
		var fila: int = int(floor((jugador.global_position.y - 1.0) / Nivel.CASILLA))
		if columna > x0 and columna <= x1 and fila >= y0 and fila <= y1:
			_empezar()
		return
	_procesar_luciernagas(delta)
	if _esperando > 0.0:
		_esperando -= delta
		if _esperando <= 0.0:
			_lanzar_oleada(_oleada + 1)
		return
	# ¿Quedan enemigos vivos en esta oleada?
	var siguen: Array = []
	for e: Variant in _vivos:
		if is_instance_valid(e) and not (e as Node).get("derrotado"):
			siguen.append(e)
	_vivos = siguen
	if _vivos.is_empty():
		if _oleada + 1 < oleadas.size():
			_esperando = ESPERA_ENTRE_OLEADAS
		else:
			_terminar()


## Luciérnagas sueltas durante la pelea, en un lugar al azar de la parte baja de la arena.
func _procesar_luciernagas(delta: float) -> void:
	if luciernagas_cada <= 0.0:
		return
	_luciernagas = _luciernagas.filter(func(l: Variant) -> bool: return is_instance_valid(l))
	_reloj_luciernaga -= delta
	if _reloj_luciernaga > 0.0 or _luciernagas.size() >= MAX_LUCIERNAGAS:
		return
	_reloj_luciernaga = luciernagas_cada
	var fila_abajo: int = y1 if y1 < 100000 else 0
	var x: int = randi_range(x0 + 2, x1 - 1)
	var y: int = fila_abajo - randi_range(0, FILAS_LUCIERNAGAS - 1)
	var luciernaga: Node2D = ESCENA_LUCIERNAGA.instantiate()
	luciernaga.set("recarga", RECARGA_LUCIERNAGA)
	luciernaga.position = Nivel.pie_de_casilla(x, y) + Vector2(0.0, -24.0)
	get_parent().add_child(luciernaga)
	_luciernagas.append(luciernaga)
	Efectos.estallido(get_parent(), luciernaga.position, COLOR_LUCIERNAGA, 12)


func _empezar() -> void:
	empezada = true
	_reloj_luciernaga = luciernagas_cada
	for puerta: Node in get_tree().get_nodes_in_group("puertas_arena"):
		if puerta.get("id_arena") == id_arena:
			puerta.call("cerrar")
	Juego.sacudir_camara(7.0, 0.4)
	_lanzar_oleada(0)


func _lanzar_oleada(indice: int) -> void:
	_oleada = indice
	if oleadas.size() > 1:
		Juego.toast("¡Oleada %d de %d!" % [indice + 1, oleadas.size()])
	else:
		Juego.toast("¡La Bruma cerró el paso! Vence a todas las sombras.")
	var contenedor: Node = get_parent()
	for dato: Array in oleadas[indice]:
		var nodo: Node2D = null
		if String(dato[0]) == "murcielagos":
			for i in range(int(dato[3])):
				var murcielago: Node2D = Nivel.crear_murcielago(i, int(dato[3]))
				murcielago.position = Nivel.pie_de_casilla(dato[1], dato[2]) + Nivel.desplazamiento_enjambre(i, int(dato[3]))
				_agregar(contenedor, murcielago)
			continue
		match String(dato[0]):
			"sombra":
				nodo = ESCENA_SOMBRA.instantiate()
				nodo.set("tipo", dato[1])
				nodo.set("limite_izq", (x0 + 1.5) * Nivel.CASILLA)
				nodo.set("limite_der", (x1 - 0.5) * Nivel.CASILLA)
				nodo.position = Nivel.pie_de_casilla(dato[2], dato[3])
			"lanzadora":
				nodo = ESCENA_LANZADORA.instantiate()
				nodo.position = Nivel.pie_de_casilla(dato[1], dato[2])
			"golem":
				if dato.size() >= 5:
					nodo = Nivel.crear_golem(dato[3], dato[4])
				else:
					nodo = Nivel.crear_golem(x0 + 1, x1 - 1)
				nodo.position = Nivel.pie_de_casilla(dato[1], dato[2])
			"frasco":
				nodo = ESCENA_FRASCO.instantiate()
				nodo.position = Nivel.pie_de_casilla(dato[1], dato[2])
		if nodo != null:
			_agregar(contenedor, nodo)


func _agregar(contenedor: Node, nodo: Node2D) -> void:
	contenedor.add_child(nodo)
	if nodo is Enemigo:
		_vivos.append(nodo)
		(nodo as Enemigo).visual.modulate.a = 0.0   # aparece poco a poco
		Efectos.estallido(contenedor, (nodo as Enemigo).centro(), COLOR_APARECER, 20)
	else:
		_extras.append(nodo)


func _terminar() -> void:
	terminada = true
	for puerta: Node in get_tree().get_nodes_in_group("puertas_arena"):
		if puerta.get("id_arena") == id_arena:
			puerta.call("abrir")
	Juego.sacudir_camara(8.0, 0.5)
	Juego.toast("La puerta de la Bruma se abrió.")


## Lía murió: si la arena no se había vencido, vuelve a empezar desde cero.
func reiniciar() -> void:
	if terminada or not empezada:
		return
	for nodo: Variant in _vivos + _extras + _luciernagas:
		if is_instance_valid(nodo):
			(nodo as Node).queue_free()
	_vivos.clear()
	_extras.clear()
	_luciernagas.clear()
	empezada = false
	_oleada = -1
	_esperando = 0.0
	for puerta: Node in get_tree().get_nodes_in_group("puertas_arena"):
		if puerta.get("id_arena") == id_arena:
			puerta.call("reiniciar")
