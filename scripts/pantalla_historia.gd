extends Control
## Pantalla de historia: texto por páginas con una linterna dibujada arriba.
## Enter o clic avanza (no antes de 0,35 s). Lee las páginas de Juego.historia_paginas.

const TIEMPO_MINIMO: float = 0.35
const TIEMPO_FUNDIDO: float = 0.6
const COLOR_TEXTO: Color = Color(0.9, 0.9, 0.86)
const COLOR_DORADO: Color = Color("e8d86a")
const COLOR_VIDRIO_ENCENDIDO: Color = Color(1.0, 0.86, 0.45)
const COLOR_VIDRIO_APAGADO: Color = Color(0.16, 0.16, 0.18)

@onready var texto: Label = $Texto
@onready var indicador: Label = $Indicador
@onready var vidrio: ColorRect = $Linterna/Vidrio
@onready var brillo: TextureRect = $Linterna/Brillo

var _paginas: Array = []
var _pagina: int = 0
var _espera: float = 0.0
var _tiempo: float = 0.0


func _ready() -> void:
	brillo.texture = Efectos.textura_radial()
	_paginas = Juego.historia_paginas
	if _paginas.is_empty():
		Juego.terminar_historia()
		return
	_mostrar_pagina()


func _process(delta: float) -> void:
	_espera += delta
	_tiempo += delta
	# La luz de la linterna tiembla un poco
	brillo.modulate.a = (0.55 + 0.08 * sin(_tiempo * 5.0)) if vidrio.color == COLOR_VIDRIO_ENCENDIDO else 0.0


func _unhandled_input(event: InputEvent) -> void:
	if _espera < TIEMPO_MINIMO or not Juego.es_avanzar(event):
		return
	get_viewport().set_input_as_handled()
	_pagina += 1
	if _pagina >= _paginas.size():
		set_process_unhandled_input(false)
		Juego.terminar_historia()
	else:
		_mostrar_pagina()


func _mostrar_pagina() -> void:
	_espera = 0.0
	var opciones: Dictionary = Juego.historia_opciones
	var apagada: bool = opciones.get("linterna_apagada", []).has(_pagina)
	var dorada: bool = opciones.get("dorada", []).has(_pagina)
	vidrio.color = COLOR_VIDRIO_APAGADO if apagada else COLOR_VIDRIO_ENCENDIDO
	texto.text = _paginas[_pagina]
	texto.add_theme_color_override("font_color", COLOR_DORADO if dorada else COLOR_TEXTO)
	indicador.text = "%d / %d" % [_pagina + 1, _paginas.size()]
	texto.modulate.a = 0.0
	create_tween().tween_property(texto, "modulate:a", 1.0, TIEMPO_FUNDIDO)
