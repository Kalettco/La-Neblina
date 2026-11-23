extends Area2D
## Corriente de aire: zona que frena la caída de Lía (caída máxima 250 px/s)
## para descensos largos y controlados. Marcador: líneas verticales tenues que suben.
## Origen = esquina SUPERIOR IZQUIERDA. "tamano" en px (lo pone el constructor).

const VELOCIDAD_LINEAS: float = 140.0
const LARGO_LINEA: float = 64.0
const SEPARACION: float = 36.0
const COLOR_LINEA: Color = Color(0.75, 0.88, 1.0, 0.16)

var tamano: Vector2 = Vector2(144.0, 480.0)

var _lineas: Array[Line2D] = []


func _ready() -> void:
	var forma: RectangleShape2D = RectangleShape2D.new()
	forma.size = tamano
	var colision: CollisionShape2D = CollisionShape2D.new()
	colision.shape = forma
	colision.position = tamano / 2.0
	add_child(colision)
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var cantidad: int = maxi(int(tamano.x / SEPARACION), 2)
	for i in range(cantidad):
		var linea: Line2D = Line2D.new()
		linea.width = 2.0
		linea.default_color = COLOR_LINEA
		linea.material = Efectos.material_sin_sombra()
		linea.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, LARGO_LINEA)])
		linea.position = Vector2((i + 0.5) * tamano.x / cantidad + randf_range(-8.0, 8.0),
			randf_range(0.0, tamano.y - LARGO_LINEA))
		add_child(linea)
		_lineas.append(linea)


func _process(delta: float) -> void:
	for linea: Line2D in _lineas:
		linea.position.y -= VELOCIDAD_LINEAS * delta
		if linea.position.y < 0.0:
			linea.position.y = tamano.y - LARGO_LINEA


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Jugador:
		(cuerpo as Jugador).corrientes += 1


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Jugador:
		(cuerpo as Jugador).corrientes = maxi((cuerpo as Jugador).corrientes - 1, 0)
