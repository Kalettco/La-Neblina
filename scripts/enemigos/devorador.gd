extends Enemigo
## EL DEVORADOR DE LUZ · jefe final (nivel 6) · vida 60.
## Masa de bruma de 480x480 que flota al centro de su arena, con un OJO (núcleo) de 96x96.
## - Solo recibe daño en el ojo, y el ojo solo se abre 2,5 s después de cada ataque
##   (brillo rojo). Daño x2 si la linterna lo ilumina cuando la chispa lo golpea.
## - Ataques al azar, sin repetir dos veces seguidas:
##     LLUVIA DE ESQUIRLAS: abanico de 5 esquirlas hacia Lía, 2 veces.
##     EMBESTIDA: se aplasta en un lado, se carga 1 s y cruza la arena a ras de suelo
##                (se esquiva subiendo a un saliente).
##     NOCHE TOTAL: 5 s casi negro y la linterna llega al 40 %; el campo de luz deja ver.
## - Fases: al 66 % invoca 4 murciélagos + 1 sombra cazadora; al 33 % invoca 1 lanzadora
##   + 4 murciélagos y ataca 30 % más rápido.
## - Durante la pelea aparecen luciérnagas sueltas que recargan luz, y el campo de luz (Q)
##   no necesita recargarse (se puede usar sin parar mientras haya luz).
## - Al morir: se deshace en chispas (3 s), la arena se ilumina y aparece el alma de Andrés.
## - Si Lía muere: vuelve al farol de la entrada y el jefe recupera toda su vida.
## El constructor pone la arena (x0..x1 columnas, y0..y1 filas libres; el suelo es y1 + 1).

const ESCENA_ESQUIRLA: PackedScene = preload("res://escenas/enemigos/esquirla.tscn")
const ESCENA_MURCIELAGO: PackedScene = preload("res://escenas/enemigos/murcielago.tscn")
const ESCENA_SOMBRA: PackedScene = preload("res://escenas/enemigos/sombra.tscn")
const ESCENA_LANZADORA: PackedScene = preload("res://escenas/enemigos/lanzadora.tscn")
const ESCENA_ALMA: PackedScene = preload("res://escenas/objetos/alma_andres.tscn")

const NOMBRE: String = "El Devorador de Luz"
const CASILLA: float = 48.0
const RADIO_CUERPO: float = 240.0
const TIEMPO_OJO_ABIERTO: float = 2.5
const PAUSA_ENTRE_ATAQUES: float = 0.8
const AVISO_LLUVIA: float = 0.6
const ENTRE_RAFAGAS: float = 0.9
const ESQUIRLAS_POR_RAFAGA: int = 5
const APERTURA_ABANICO: float = 0.5           # radianes a cada lado
const TIEMPO_BAJAR: float = 0.8
const TIEMPO_CARGA: float = 1.0
const VELOCIDAD_EMBESTIDA: float = 1100.0
const ALTO_BARRIDO: float = 120.0             # franja peligrosa sobre el suelo
const DANO_EMBESTIDA: float = 30.0
const DURACION_NOCHE: float = 5.0
const TIEMPO_MUERTE: float = 3.0
const MULTIPLICADOR_RAPIDO: float = 1.3
const VIDA_FASE_2: int = 40                   # 66 %
const VIDA_FASE_3: int = 20                   # 33 %
const LUCIERNAGAS_CADA: float = 3.0
const MAX_LUCIERNAGAS: int = 4
const RECARGA_LUCIERNAGA: float = 15.0
const COLOR_CUERPO: Color = Color(0.1, 0.05, 0.14)
const COLOR_BORDE: Color = Color(0.5, 0.2, 0.7)
const COLOR_OJO_ABIERTO: Color = Color(1.0, 0.2, 0.15)
const COLOR_ALMA: Color = Color(1.0, 0.85, 0.45)

enum Estado { DORMIDO, PAUSA, LLUVIA, EMBESTIDA, NOCHE, OJO_ABIERTO, MURIENDO, VENCIDO }
enum Ataque { LLUVIA, EMBESTIDA, NOCHE }

var x0: int = 0
var x1: int = 0
var y0: int = 0
var y1: int = 0
var id_puertas: String = "jefe"

var _estado: Estado = Estado.DORMIDO
var _reloj: float = 0.0
var _tiempo: float = 0.0
var _ultimo_ataque: int = -1
var _rafagas: int = 0
var _paso_embestida: int = 0
var _desde: Vector2 = Vector2.ZERO
var _hasta: Vector2 = Vector2.ZERO
var _progreso: float = 0.0
var _disparo_noche: bool = false
var _ojo_abierto: bool = false
var _rapido: bool = false
var _fase_2: bool = false
var _fase_3: bool = false
var _aviso_ojo: float = 0.0
var _primer_ojo: bool = true
var _invocados: Array = []
var _luciernagas: Array = []
var _reloj_luciernaga: float = 0.0
var _reloj_chispas: float = 0.0

var _reposo: Vector2 = Vector2.ZERO
var _suelo_y: float = 0.0
var _cuerpo: Polygon2D = null
var _borde: Line2D = null
var _ojo: Node2D = null
var _iris: Polygon2D = null
var _luz_ojo: PointLight2D = null
var _luz_cuerpo: PointLight2D = null

@onready var barrido: Area2D = $Barrido


func _ready() -> void:
	super._ready()
	add_to_group("jefes")
	_reposo = Vector2((x0 + x1 + 1) / 2.0 * CASILLA, (y0 + (y1 - y0) * 0.38) * CASILLA)
	_suelo_y = (y1 + 1) * CASILLA
	global_position = _reposo
	_construir_visual()


func centro() -> Vector2:
	return global_position


# --- Daño ---

func recibir_dano(cantidad: int, desde: Vector2) -> void:
	if _estado == Estado.DORMIDO or _estado == Estado.MURIENDO or _estado == Estado.VENCIDO:
		return
	if not _ojo_abierto:
		Efectos.estallido(get_parent(), desde, Color(0.5, 0.45, 0.6), 6)
		if _aviso_ojo <= 0.0:
			_aviso_ojo = 5.0
			Juego.toast("El ojo está cerrado. Esquiva su ataque y dispárale cuando se abra.")
		return
	var jugador: Jugador = Juego.jugador
	var dano: int = cantidad
	if is_instance_valid(jugador) and jugador.esta_iluminado(centro()):
		dano *= 2   # el ojo iluminado por la linterna duele el doble
	vida -= dano
	_destello = TIEMPO_DESTELLO
	Audio.sfx_impacto()
	Juego.avisar_jefe(NOMBRE, maxi(vida, 0), vida_maxima)
	if vida <= 0:
		_empezar_muerte()
		return
	_revisar_fases()


func _revisar_fases() -> void:
	if not _fase_2 and vida <= VIDA_FASE_2:
		_fase_2 = true
		Juego.toast("¡El Devorador llama a la Bruma!")
		Juego.sacudir_camara(8.0, 0.4)
		_invocar_murcielagos(x0 + 4, y0 + 3, 4)
		var sombra: Node2D = ESCENA_SOMBRA.instantiate()
		sombra.set("tipo", "cazadora")
		sombra.set("limite_izq", (x0 + 1.5) * CASILLA)
		sombra.set("limite_der", (x1 - 0.5) * CASILLA)
		_invocar(sombra, Nivel.pie_de_casilla(x1 - 3, y1))
	if not _fase_3 and vida <= VIDA_FASE_3:
		_fase_3 = true
		_rapido = true
		Juego.toast("¡El Devorador está furioso!")
		Juego.sacudir_camara(10.0, 0.5)
		_invocar(ESCENA_LANZADORA.instantiate(), Nivel.pie_de_casilla(x0 + 3, y0 + 5))
		_invocar_murcielagos(x1 - 4, y0 + 3, 4)


func _invocar_murcielagos(x: int, y: int, cantidad: int) -> void:
	for i in range(cantidad):
		var murcielago: Node2D = Nivel.crear_murcielago(i, cantidad)
		_invocar(murcielago, Nivel.pie_de_casilla(x, y) + Nivel.desplazamiento_enjambre(i, cantidad))


func _invocar(nodo: Node2D, posicion: Vector2) -> void:
	nodo.position = posicion
	get_parent().add_child(nodo)
	_invocados.append(nodo)
	Efectos.estallido(get_parent(), posicion + Vector2(0.0, -24.0), COLOR_BORDE, 20)


## Lía murió: vuelve a dormir con toda su vida (salvo si ya está vencido).
func reiniciar() -> void:
	if _estado == Estado.VENCIDO:
		return
	super.reiniciar()
	vida = vida_maxima
	_estado = Estado.DORMIDO
	_ojo_abierto = false
	_rapido = false
	_fase_2 = false
	_fase_3 = false
	_ultimo_ataque = -1
	Juego.noche_total = false
	Juego.campo_sin_recarga = false
	global_position = _reposo
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE
	visual.modulate.a = 1.0
	_limpiar(_invocados)
	_limpiar(_luciernagas)
	Juego.ocultar_jefe()
	for puerta: Node in get_tree().get_nodes_in_group("puertas_arena"):
		if puerta.get("id_arena") == id_puertas:
			puerta.call("reiniciar")


func _limpiar(lista: Array) -> void:
	for nodo: Variant in lista:
		if is_instance_valid(nodo):
			(nodo as Node).queue_free()
	lista.clear()


# --- Comportamiento ---

func _physics_process(delta: float) -> void:
	_tiempo += delta
	_aviso_ojo = maxf(_aviso_ojo - delta, 0.0)
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return
	var paso: float = delta * (MULTIPLICADOR_RAPIDO if _rapido else 1.0)
	match _estado:
		Estado.DORMIDO:
			if not jugador.muerto and _dentro_de_la_arena(jugador.global_position):
				_despertar()
		Estado.PAUSA:
			_flotar(delta)
			_reloj -= paso
			if _reloj <= 0.0:
				_elegir_ataque()
		Estado.LLUVIA:
			_flotar(delta)
			_reloj -= paso
			if _reloj <= 0.0:
				if _rafagas < 2:
					_disparar_abanico(jugador)
					_rafagas += 1
					_reloj = ENTRE_RAFAGAS
				else:
					_abrir_ojo()
		Estado.EMBESTIDA:
			_procesar_embestida(jugador, paso)
		Estado.NOCHE:
			_flotar(delta)
			_reloj -= paso
			if not _disparo_noche and _reloj <= DURACION_NOCHE / 2.0:
				_disparo_noche = true
				_disparar_abanico(jugador)
			if _reloj <= 0.0:
				Juego.noche_total = false
				_abrir_ojo()
		Estado.OJO_ABIERTO:
			_flotar(delta)
			_reloj -= paso
			if _reloj <= 0.0:
				_ojo_abierto = false
				_estado = Estado.PAUSA
				_reloj = PAUSA_ENTRE_ATAQUES
		Estado.MURIENDO:
			_procesar_muerte(delta)
	if _estado != Estado.DORMIDO and _estado != Estado.MURIENDO and _estado != Estado.VENCIDO:
		_procesar_luciernagas(delta)
	_destello = maxf(_destello - delta, 0.0)
	_actualizar_visual(delta)


func _dentro_de_la_arena(punto: Vector2) -> bool:
	var columna: int = floori(punto.x / CASILLA)
	var fila: int = floori((punto.y - 1.0) / CASILLA)
	return columna > x0 and columna <= x1 and fila >= y0 and fila <= y1


func _despertar() -> void:
	_estado = Estado.PAUSA
	_reloj = 1.5
	for puerta: Node in get_tree().get_nodes_in_group("puertas_arena"):
		if puerta.get("id_arena") == id_puertas:
			puerta.call("cerrar")
	Juego.avisar_jefe(NOMBRE, vida, vida_maxima)
	Juego.toast("¡El Devorador de Luz despertó! Aquí tu campo de luz no necesita recargarse: usa Q sin parar.")
	# Mientras viva el jefe, Q se puede usar sin esperar la recarga
	Juego.campo_sin_recarga = true
	var jugador: Jugador = Juego.jugador
	if is_instance_valid(jugador):
		jugador.recarga_campo_restante = 0.0
	Juego.sacudir_camara(12.0, 0.6)
	Audio.musica("jefe")
	Audio.sfx_jefe_ataque()
	_reloj_luciernaga = LUCIERNAGAS_CADA


func _flotar(delta: float) -> void:
	var objetivo: Vector2 = _reposo + Vector2(sin(_tiempo * 0.7) * 120.0, sin(_tiempo * 1.1) * 30.0)
	global_position = global_position.move_toward(objetivo, 220.0 * delta)


## Elige un ataque al azar que no sea el mismo de la vez anterior.
func _elegir_ataque() -> void:
	var opciones: Array = [Ataque.LLUVIA, Ataque.EMBESTIDA, Ataque.NOCHE]
	opciones.erase(_ultimo_ataque)
	var ataque: int = opciones[randi() % opciones.size()]
	_ultimo_ataque = ataque
	Audio.sfx_jefe_ataque()
	match ataque:
		Ataque.LLUVIA:
			_estado = Estado.LLUVIA
			_rafagas = 0
			_reloj = AVISO_LLUVIA
		Ataque.EMBESTIDA:
			_estado = Estado.EMBESTIDA
			_paso_embestida = 0
			_progreso = 0.0
			_desde = global_position
			# Empieza en el lado contrario a Lía y cruza hacia ella
			var lado: float = -1.0 if Juego.jugador.global_position.x > _reposo.x else 1.0
			_hasta = Vector2(_reposo.x + lado * _media_carrera(), _suelo_y - ALTO_BARRIDO / 2.0)
		Ataque.NOCHE:
			_estado = Estado.NOCHE
			_reloj = DURACION_NOCHE
			_disparo_noche = false
			Juego.noche_total = true
			Juego.toast("La Bruma apagó todas las luces. ¡Usa el campo de luz!")


## Distancia desde el centro hasta donde empieza/termina la embestida.
func _media_carrera() -> float:
	return (x1 - x0 + 1) * CASILLA / 2.0 - 210.0


func _disparar_abanico(jugador: Jugador) -> void:
	var objetivo: Vector2 = jugador.global_position + Vector2(0.0, -42.0)
	var base: Vector2 = (objetivo - centro()).normalized()
	for i in range(ESQUIRLAS_POR_RAFAGA):
		var t: float = float(i) / (ESQUIRLAS_POR_RAFAGA - 1) * 2.0 - 1.0
		var esquirla: Node2D = ESCENA_ESQUIRLA.instantiate()
		esquirla.global_position = centro()
		esquirla.set("direccion", base.rotated(t * APERTURA_ABANICO))
		get_parent().add_child(esquirla)
	Audio.sfx_esquirla()


## Bajar al suelo en un lado -> cargar 1 s -> cruzar -> volver al centro.
func _procesar_embestida(jugador: Jugador, paso: float) -> void:
	match _paso_embestida:
		0:   # baja y se aplasta
			_progreso = minf(_progreso + paso / TIEMPO_BAJAR, 1.0)
			global_position = _desde.lerp(_hasta, smoothstep(0.0, 1.0, _progreso))
			if _progreso >= 1.0:
				_paso_embestida = 1
				_reloj = TIEMPO_CARGA
		1:   # se carga (tiembla)
			_reloj -= paso
			if _reloj <= 0.0:
				_paso_embestida = 2
				_desde = global_position
				_hasta = Vector2(_reposo.x - signf(global_position.x - _reposo.x) * _media_carrera(), global_position.y)
		2:   # cruza la arena: la franja baja hace daño
			global_position.x = move_toward(global_position.x, _hasta.x, VELOCIDAD_EMBESTIDA * paso)
			if not jugador.muerto and barrido.overlaps_body(jugador):
				jugador.recibir_dano(DANO_EMBESTIDA, global_position.x)
			if absf(global_position.x - _hasta.x) < 1.0:
				_paso_embestida = 3
				_progreso = 0.0
				_desde = global_position
				Juego.sacudir_camara(8.0, 0.3)
		3:   # vuelve a flotar al centro
			_progreso = minf(_progreso + paso / TIEMPO_BAJAR, 1.0)
			global_position = _desde.lerp(_reposo, smoothstep(0.0, 1.0, _progreso))
			if _progreso >= 1.0:
				_abrir_ojo()


func _abrir_ojo() -> void:
	_estado = Estado.OJO_ABIERTO
	_ojo_abierto = true
	_reloj = TIEMPO_OJO_ABIERTO
	if _primer_ojo:
		_primer_ojo = false
		Juego.toast("¡El ojo está abierto! Ilumínalo y dispárale.")


## Luciérnagas sueltas en la mitad baja de la arena (recargan luz para seguir luchando).
func _procesar_luciernagas(delta: float) -> void:
	_luciernagas = _luciernagas.filter(func(l: Variant) -> bool: return is_instance_valid(l))
	_reloj_luciernaga -= delta
	if _reloj_luciernaga > 0.0 or _luciernagas.size() >= MAX_LUCIERNAGAS:
		return
	_reloj_luciernaga = LUCIERNAGAS_CADA
	var luciernaga: Node2D = ESCENA_LUCIERNAGA.instantiate()
	luciernaga.set("recarga", RECARGA_LUCIERNAGA)
	var celda: Vector2 = Nivel.pie_de_casilla(randi_range(x0 + 2, x1 - 2), y1 - randi_range(0, 8))
	luciernaga.position = celda + Vector2(0.0, -24.0)
	get_parent().add_child(luciernaga)
	_luciernagas.append(luciernaga)
	Efectos.estallido(get_parent(), luciernaga.position, Color(1.0, 0.92, 0.35), 12)


# --- Muerte ---

func _empezar_muerte() -> void:
	_estado = Estado.MURIENDO
	_reloj = TIEMPO_MUERTE
	_ojo_abierto = false
	Juego.noche_total = false
	Juego.campo_sin_recarga = false
	Juego.todas_asustadas = true
	Juego.ocultar_jefe()
	Audio.sfx_jefe_muere()
	for nodo: Variant in _invocados:
		if is_instance_valid(nodo) and not (nodo as Node).get("derrotado"):
			(nodo as Node).call("morir")
	_invocados.clear()
	for proyectil: Node in get_tree().get_nodes_in_group("proyectiles_enemigos"):
		proyectil.call("destruir")


## 3 s: tiembla y se deshace en chispas.
func _procesar_muerte(delta: float) -> void:
	_reloj -= delta
	global_position = global_position.move_toward(_reposo, 200.0 * delta)
	visual.position = Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	visual.modulate.a = clampf(_reloj / TIEMPO_MUERTE, 0.0, 1.0)
	_reloj_chispas -= delta
	if _reloj_chispas <= 0.0:
		_reloj_chispas = 0.12
		var punto: Vector2 = centro() + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * RADIO_CUERPO * 0.8
		Efectos.estallido(get_parent(), punto, COLOR_ALMA if randf() < 0.3 else COLOR_BORDE, 16)
		Juego.sacudir_camara(4.0, 0.15)
	if _reloj <= 0.0:
		_vencer()


func _vencer() -> void:
	_estado = Estado.VENCIDO
	derrotado = true
	visual.visible = false
	Juego.registrar_sombra_destruida()
	Juego.curando = true   # la arena se ilumina
	Juego.sacudir_camara(14.0, 0.8)
	Efectos.estallido(get_parent(), centro(), COLOR_ALMA, 80)
	for puerta: Node in get_tree().get_nodes_in_group("puertas_arena"):
		if puerta.get("id_arena") == id_puertas:
			puerta.call("abrir")
	var alma: Node2D = ESCENA_ALMA.instantiate()
	alma.position = Nivel.pie_de_casilla(floori((x0 + x1) / 2.0), y1)
	get_parent().add_child.call_deferred(alma)
	Juego.toast("Entre las chispas flota una luz dorada...")


# --- Visual ---

func _actualizar_visual(delta: float) -> void:
	if _estado == Estado.VENCIDO:
		return
	# Cuerpo que ondula
	var puntos: PackedVector2Array = PackedVector2Array()
	for i in range(40):
		var angulo: float = TAU * i / 40.0
		var radio: float = RADIO_CUERPO * (1.0 + 0.06 * sin(angulo * 5.0 + _tiempo * 2.0) + 0.03 * sin(angulo * 9.0 - _tiempo * 3.0))
		puntos.append(Vector2(cos(angulo), sin(angulo)) * radio)
	_cuerpo.polygon = puntos
	puntos.append(puntos[0])
	_borde.points = puntos
	# Aplastado durante la embestida
	var aplastado: bool = _estado == Estado.EMBESTIDA and _paso_embestida in [1, 2]
	var bajando: bool = _estado == Estado.EMBESTIDA and _paso_embestida in [0, 3]
	var escala_y: float = ALTO_BARRIDO / (RADIO_CUERPO * 2.0) if aplastado else 1.0
	if bajando:
		escala_y = lerpf(1.0, ALTO_BARRIDO / (RADIO_CUERPO * 2.0), _progreso if _paso_embestida == 0 else 1.0 - _progreso)
	visual.scale = Vector2(0.9 if aplastado else 1.0, escala_y)
	if _estado != Estado.MURIENDO:
		var temblor: Vector2 = Vector2(randf_range(-6.0, 6.0), 0.0) if (_estado == Estado.EMBESTIDA and _paso_embestida == 1) else Vector2.ZERO
		visual.position = temblor
	barrido.monitoring = aplastado
	# Ojo: se abre (rojo) después de atacar; brilla morado mientras prepara la lluvia
	var objetivo_ojo: float = 1.0 if _ojo_abierto else 0.12
	_ojo.scale.y = move_toward(_ojo.scale.y, objetivo_ojo, 6.0 * delta)
	_iris.color = COLOR_OJO_ABIERTO if _ojo_abierto else Color(0.35, 0.15, 0.4)
	var noche: bool = Juego.noche_total and not Juego.campo_activo()
	_luz_ojo.enabled = _ojo_abierto and not noche
	_luz_ojo.energy = 1.2 + 0.3 * sin(_tiempo * 8.0)
	var preparando: bool = _estado == Estado.LLUVIA
	_luz_cuerpo.energy = (1.2 if preparando else 0.6) * (0.0 if noche else 1.0)
	_borde.default_color.a = 0.0 if noche else 0.55
	var brillo: float = 3.0 if _destello > 0.0 else 1.0
	_ojo.modulate = Color(brillo, brillo, brillo)


## Marcador: masa de bruma 480x480 con borde morado tenue y un ojo de 96x96 en el centro.
func _construir_visual() -> void:
	_luz_cuerpo = PointLight2D.new()
	_luz_cuerpo.texture = Efectos.textura_radial()
	_luz_cuerpo.texture_scale = Efectos.escala_para_radio(320.0)
	_luz_cuerpo.color = COLOR_BORDE
	_luz_cuerpo.energy = 0.6
	visual.add_child(_luz_cuerpo)
	_cuerpo = Polygon2D.new()
	_cuerpo.color = COLOR_CUERPO
	_cuerpo.z_index = -1
	visual.add_child(_cuerpo)
	_borde = Line2D.new()
	_borde.width = 4.0
	_borde.default_color = Color(COLOR_BORDE, 0.55)
	_borde.material = Efectos.material_sin_sombra()
	_borde.z_index = -1
	visual.add_child(_borde)
	_ojo = Node2D.new()
	visual.add_child(_ojo)
	var blanco: Polygon2D = Polygon2D.new()
	var iris: PackedVector2Array = PackedVector2Array()
	var ojo: PackedVector2Array = PackedVector2Array()
	for i in range(24):
		var angulo: float = TAU * i / 24.0
		ojo.append(Vector2(cos(angulo) * 48.0, sin(angulo) * 30.0))
		iris.append(Vector2(cos(angulo), sin(angulo)) * 18.0)
	blanco.polygon = ojo
	blanco.color = Color(0.75, 0.7, 0.8)
	_ojo.add_child(blanco)
	_iris = Polygon2D.new()
	_iris.polygon = iris
	_ojo.add_child(_iris)
	_luz_ojo = PointLight2D.new()
	_luz_ojo.texture = Efectos.textura_radial()
	_luz_ojo.texture_scale = Efectos.escala_para_radio(140.0)
	_luz_ojo.color = COLOR_OJO_ABIERTO
	_luz_ojo.enabled = false
	visual.add_child(_luz_ojo)
	_ojo.scale.y = 0.12
