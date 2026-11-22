extends CanvasLayer
## HUD: barra de LUZ, zona, contadores, avisos (toast) y recuadro de carteles.
## Solo escucha las señales del autoload Juego.

const COLOR_TOAST: Color = Color("e8d86a")
const COLOR_LUZ: Color = Color(1.0, 0.86, 0.55)
const COLOR_BARRA_BAJA: Color = Color(1.0, 0.45, 0.35)
const DURACION_TOAST: float = 2.6
const ENERGIA_BAJA: float = 25.0

@onready var barra_luz: ProgressBar = $BarraLuz
@onready var etiqueta_zona: Label = $Zona
@onready var etiqueta_luciernagas: Label = $Luciernagas
@onready var etiqueta_guardianas: Label = $Guardianas
@onready var etiqueta_toast: Label = $Toast
@onready var cartel: PanelContainer = $Cartel
@onready var texto_cartel: Label = $Cartel/Texto

var _tween_toast: Tween = null
var _estilo_cartel: StyleBoxFlat = null
var _estilo_nota: StyleBoxFlat = null


func _ready() -> void:
	_preparar_estilos()
	etiqueta_toast.modulate.a = 0.0
	cartel.visible = false
	etiqueta_guardianas.visible = Juego.nivel_actual == 1

	Juego.energia_cambiada.connect(_al_cambiar_energia)
	Juego.luciernagas_cambiadas.connect(_al_cambiar_luciernagas)
	Juego.guardianas_cambiadas.connect(_al_cambiar_guardianas)
	Juego.zona_cambiada.connect(_al_cambiar_zona)
	Juego.toast_pedido.connect(_al_pedir_toast)
	Juego.cartel_cambiado.connect(_al_cambiar_cartel)

	# Valores iniciales
	_al_cambiar_luciernagas(Juego.luciernagas_liberadas(), Juego.luciernagas_total())
	_al_cambiar_guardianas(Juego.estadisticas["guardianas"])
	_al_cambiar_zona(Juego.zona_actual)


func _al_cambiar_energia(energia: float, maxima: float) -> void:
	barra_luz.max_value = maxima
	barra_luz.value = energia
	barra_luz.modulate = COLOR_BARRA_BAJA if energia < ENERGIA_BAJA else Color.WHITE


func _al_cambiar_luciernagas(liberadas: int, total: int) -> void:
	etiqueta_luciernagas.text = "Luciérnagas %d/%d" % [liberadas, total]


func _al_cambiar_guardianas(cantidad: int) -> void:
	etiqueta_guardianas.text = "Guardianas %d/3" % cantidad


func _al_cambiar_zona(nombre: String) -> void:
	etiqueta_zona.text = nombre


func _al_pedir_toast(texto: String) -> void:
	etiqueta_toast.text = texto
	if _tween_toast != null and _tween_toast.is_valid():
		_tween_toast.kill()
	etiqueta_toast.modulate.a = 1.0
	_tween_toast = create_tween()
	_tween_toast.tween_interval(DURACION_TOAST - 0.4)
	_tween_toast.tween_property(etiqueta_toast, "modulate:a", 0.0, 0.4)


func _al_cambiar_cartel(texto: String, es_nota: bool) -> void:
	if texto == "":
		cartel.visible = false
		return
	texto_cartel.text = texto
	cartel.add_theme_stylebox_override("panel", _estilo_nota if es_nota else _estilo_cartel)
	var color_texto: Color = Color(0.22, 0.16, 0.1) if es_nota else Color(0.96, 0.93, 0.86)
	texto_cartel.add_theme_color_override("font_color", color_texto)
	cartel.visible = true


func _preparar_estilos() -> void:
	# Barra de luz: relleno cálido sobre fondo oscuro
	var relleno: StyleBoxFlat = StyleBoxFlat.new()
	relleno.bg_color = COLOR_LUZ
	relleno.set_corner_radius_all(6)
	var fondo: StyleBoxFlat = StyleBoxFlat.new()
	fondo.bg_color = Color(0.05, 0.06, 0.1, 0.85)
	fondo.border_color = Color(0.55, 0.5, 0.38)
	fondo.set_border_width_all(2)
	fondo.set_corner_radius_all(6)
	barra_luz.add_theme_stylebox_override("fill", relleno)
	barra_luz.add_theme_stylebox_override("background", fondo)

	# Cartel: tabla oscura con borde dorado
	_estilo_cartel = StyleBoxFlat.new()
	_estilo_cartel.bg_color = Color(0.1, 0.08, 0.06, 0.92)
	_estilo_cartel.border_color = COLOR_TOAST
	_estilo_cartel.set_border_width_all(4)
	_estilo_cartel.set_corner_radius_all(10)
	_estilo_cartel.set_content_margin_all(28)

	# Nota de papá: papel claro
	_estilo_nota = StyleBoxFlat.new()
	_estilo_nota.bg_color = Color(0.93, 0.89, 0.78, 0.96)
	_estilo_nota.border_color = Color(0.72, 0.64, 0.48)
	_estilo_nota.set_border_width_all(3)
	_estilo_nota.set_corner_radius_all(4)
	_estilo_nota.set_content_margin_all(28)
