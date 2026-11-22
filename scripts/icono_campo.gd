extends Control
## Ícono circular del campo de luz (64x64), junto a la barra de LUZ.
## - Recargando: un arco se llena poco a poco.
## - Listo: círculo lleno que late y brilla.
## - Activo: anillo blanco que se vacía mientras dura el campo.
## Solo se ve si Lía ya tiene el campo de luz.

const COLOR_FONDO: Color = Color(0.05, 0.06, 0.1, 0.85)
const COLOR_BORDE: Color = Color(0.55, 0.5, 0.38)
const COLOR_LISTO: Color = Color(1.0, 0.9, 0.55)
const COLOR_CARGA: Color = Color(0.7, 0.62, 0.4)

var _tiempo: float = 0.0


func _process(delta: float) -> void:
	_tiempo += delta
	visible = Juego.tiene_campo
	if visible:
		queue_redraw()


func _draw() -> void:
	var centro: Vector2 = size / 2.0
	var radio: float = minf(size.x, size.y) / 2.0 - 4.0
	draw_circle(centro, radio, COLOR_FONDO)
	draw_arc(centro, radio, 0.0, TAU, 48, COLOR_BORDE, 2.0)
	var jugador: Jugador = Juego.jugador
	if not is_instance_valid(jugador):
		return
	if jugador.campo_activo():
		# Activo: anillo que se vacía
		var resto: float = jugador.tiempo_campo / jugador.duracion_campo
		draw_arc(centro, radio - 5.0, -PI / 2.0, -PI / 2.0 + TAU * resto, 48, Color.WHITE, 6.0)
	elif jugador.recarga_campo_restante > 0.0:
		# Recargando: arco que se llena
		var avance: float = 1.0 - jugador.recarga_campo_restante / jugador.recarga_campo
		draw_arc(centro, radio - 5.0, -PI / 2.0, -PI / 2.0 + TAU * avance, 48, COLOR_CARGA, 6.0)
	else:
		# Listo: brilla y late
		var pulso: float = 0.75 + 0.25 * sin(_tiempo * 4.0)
		draw_circle(centro, (radio - 6.0) * pulso, Color(COLOR_LISTO, 0.9))
		draw_arc(centro, radio + 2.0, 0.0, TAU, 48, Color(COLOR_LISTO, 0.5 * pulso), 3.0)
	# Letra de la tecla
	var fuente: Font = get_theme_default_font()
	draw_string(fuente, centro + Vector2(-9.0, 9.0), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.1, 0.08, 0.05) if not jugador.campo_activo() and jugador.recarga_campo_restante <= 0.0 else Color(0.9, 0.9, 0.86))
