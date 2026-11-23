extends Node2D
## Fauces de la Bruma: dos paredes (de arriba y de abajo) que se cierran por turnos
## sobre un pasillo. Ciclo: abierta 1,4 s -> tiembla (aviso) 0,5 s -> se cierra en 0,12 s
## -> cerrada 0,5 s -> se abre en 0,35 s. Si Lía está entre las paredes cuando se
## cierran, se desmaya. "desfase" (0 a 1) adelanta el ciclo para que se turnen.
## Mide "ancho_casillas" de ancho y "alto_casillas" de alto.
## Origen = esquina SUPERIOR IZQUIERDA de la casilla de arriba.

const CASILLA: float = 48.0
const TIEMPO_ABIERTA: float = 1.4
const TIEMPO_AVISO: float = 0.5
const TIEMPO_CERRANDO: float = 0.12
const TIEMPO_CERRADA: float = 0.5
const TIEMPO_ABRIENDO: float = 0.35
const CICLO: float = TIEMPO_ABIERTA + TIEMPO_AVISO + TIEMPO_CERRANDO + TIEMPO_CERRADA + TIEMPO_ABRIENDO
const CIERRE_PELIGROSO: float = 0.8    # desde este cierre (0 = abierta, 1 = cerrada) atrapa a Lía
const COLOR_RAIZ: Color = Color(0.14, 0.07, 0.17)
const COLOR_DIENTE: Color = Color(0.55, 0.22, 0.65)

var ancho_casillas: int = 2
var alto_casillas: int = 5
var desfase: float = 0.0

var _arriba: Node2D = null
var _abajo: Node2D = null


func _ready() -> void:
	_arriba = _crear_mandibula(true)
	_abajo = _crear_mandibula(false)


func _physics_process(_delta: float) -> void:
	var t: float = fposmod(Time.get_ticks_msec() / 1000.0 + desfase * CICLO, CICLO)
	var cierre: float = 0.0
	var temblor: float = 0.0
	if t < TIEMPO_ABIERTA:
		cierre = 0.0
	elif t < TIEMPO_ABIERTA + TIEMPO_AVISO:
		cierre = 0.08
		temblor = randf_range(-3.0, 3.0)
	elif t < TIEMPO_ABIERTA + TIEMPO_AVISO + TIEMPO_CERRANDO:
		cierre = lerpf(0.08, 1.0, (t - TIEMPO_ABIERTA - TIEMPO_AVISO) / TIEMPO_CERRANDO)
	elif t < CICLO - TIEMPO_ABRIENDO:
		cierre = 1.0
	else:
		cierre = 1.0 - (t - (CICLO - TIEMPO_ABRIENDO)) / TIEMPO_ABRIENDO
	# Cada mandíbula recorre la mitad del alto: abiertas quedan dentro del techo y del suelo
	var mitad: float = alto_casillas * CASILLA / 2.0
	_arriba.position = Vector2(temblor, -mitad + mitad * cierre)
	_abajo.position = Vector2(-temblor, alto_casillas * CASILLA + mitad - mitad * cierre)
	if cierre >= CIERRE_PELIGROSO:
		_atrapar()


## Lía está dentro del pasillo de las fauces.
func _atrapar() -> void:
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador) or jugador.muerto:
		return
	var izquierda: float = global_position.x
	var derecha: float = izquierda + ancho_casillas * CASILLA
	var arriba: float = global_position.y
	var abajo: float = arriba + alto_casillas * CASILLA
	var x: float = jugador.global_position.x
	var y: float = jugador.global_position.y
	if x + 14.0 > izquierda and x - 14.0 < derecha and y > arriba and y - 84.0 < abajo:
		Juego.morir("Las fauces de la Bruma se cerraron sobre ti.")


## Mandíbula: bloque de raíz negra del ancho del pasillo y la mitad de alto, con dientes.
## (arriba: cuelga hacia abajo desde su origen; abajo: sube desde su origen)
func _crear_mandibula(es_arriba: bool) -> Node2D:
	var mandibula: Node2D = Node2D.new()
	var ancho: float = ancho_casillas * CASILLA
	var largo: float = alto_casillas * CASILLA / 2.0
	var cuerpo: ColorRect = ColorRect.new()
	cuerpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cuerpo.color = COLOR_RAIZ
	cuerpo.size = Vector2(ancho, largo)
	cuerpo.position = Vector2(0.0, 0.0 if es_arriba else -largo)
	mandibula.add_child(cuerpo)
	var dientes: Polygon2D = Polygon2D.new()
	var puntos: PackedVector2Array = PackedVector2Array()
	var borde: float = largo if es_arriba else -largo
	var punta: float = 14.0 if es_arriba else -14.0
	var cantidad: int = int(ancho / 16.0)
	for i in range(cantidad + 1):
		puntos.append(Vector2(i * 16.0, borde))
		if i < cantidad:
			puntos.append(Vector2(i * 16.0 + 8.0, borde + punta))
	puntos.append(Vector2(ancho, borde - punta))
	puntos.append(Vector2(0.0, borde - punta))
	dientes.polygon = puntos
	dientes.color = COLOR_DIENTE
	dientes.material = Efectos.material_sin_sombra()
	mandibula.add_child(dientes)
	add_child(mandibula)
	return mandibula
