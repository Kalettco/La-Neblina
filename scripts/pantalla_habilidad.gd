extends Control
## Pantalla "NUEVA HABILIDAD": título, explicación y Enter/clic para continuar.
## Lee Juego.habilidad_titulo y Juego.habilidad_texto.

const TIEMPO_MINIMO: float = 0.6   # un poco más largo: hay que leer el control nuevo

@onready var titulo: Label = $Caja/Titulo
@onready var texto: Label = $Caja/Texto
@onready var caja: Control = $Caja
@onready var brillo: TextureRect = $Brillo

var _espera: float = 0.0
var _tiempo: float = 0.0


func _ready() -> void:
	titulo.text = Juego.habilidad_titulo
	texto.text = Juego.habilidad_texto
	brillo.texture = Efectos.textura_radial()
	caja.modulate.a = 0.0
	caja.scale = Vector2(0.92, 0.92)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(caja, "modulate:a", 1.0, 0.6)
	tween.tween_property(caja, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_espera += delta
	_tiempo += delta
	brillo.modulate.a = 0.35 + 0.1 * sin(_tiempo * 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if _espera < TIEMPO_MINIMO or not Juego.es_avanzar(event):
		return
	get_viewport().set_input_as_handled()
	set_process_unhandled_input(false)
	Juego.terminar_habilidad()
