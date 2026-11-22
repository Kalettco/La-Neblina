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
##   ["frasco", x, y]          (aparece al empezar esa oleada)

const ESCENA_SOMBRA: PackedScene = preload("res://escenas/enemigos/sombra.tscn")
const ESCENA_LANZADORA: PackedScene = preload("res://escenas/enemigos/lanzadora.tscn")
const ESCENA_FRASCO: PackedScene = preload("res://escenas/objetos/frasco.tscn")
const ESPERA_ENTRE_OLEADAS: float = 1.2
const COLOR_APARECER: Color = Color(0.4, 0.2, 0.55)

var id_arena: String = "arena"
var x0: int = 0                      # columnas (casillas) de la arena
var x1: int = 0
var oleadas: Array = []

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
		if columna > x0 and columna <= x1:
			_empezar()
		return
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


func _empezar() -> void:
	empezada = true
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
			"frasco":
				nodo = ESCENA_FRASCO.instantiate()
				nodo.position = Nivel.pie_de_casilla(dato[1], dato[2])
		if nodo == null:
			continue
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
	for nodo: Node in _vivos + _extras:
		if is_instance_valid(nodo):
			nodo.queue_free()
	_vivos.clear()
	_extras.clear()
	empezada = false
	_oleada = -1
	_esperando = 0.0
	for puerta: Node in get_tree().get_nodes_in_group("puertas_arena"):
		if puerta.get("id_arena") == id_arena:
			puerta.call("reiniciar")
