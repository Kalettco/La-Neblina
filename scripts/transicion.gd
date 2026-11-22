extends CanvasLayer
## Autoload "Transicion": fundido a negro entre escenas.
## Uso: Transicion.cambiar_escena("res://...tscn")

const TIEMPO_FUNDIDO: float = 0.35

var _cortina: ColorRect = null
var _ocupado: bool = false
var _ruta_pendiente: String = ""


func _ready() -> void:
	layer = 100                                  # encima de todo
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cortina = ColorRect.new()
	_cortina.color = Color(0.0, 0.0, 0.0, 1.0)
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.modulate.a = 0.0
	add_child(_cortina)


## Oscurece, cambia de escena y vuelve a aclarar.
func cambiar_escena(ruta: String) -> void:
	_ruta_pendiente = ruta
	if _ocupado:
		return   # ya hay un fundido en curso: usará la última ruta pedida
	_ocupado = true
	_cortina.mouse_filter = Control.MOUSE_FILTER_STOP   # sin clics durante el fundido
	get_tree().paused = true                             # la escena vieja se congela
	var oscurecer: Tween = create_tween()
	oscurecer.tween_property(_cortina, "modulate:a", 1.0, TIEMPO_FUNDIDO)
	await oscurecer.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(_ruta_pendiente)
	await get_tree().process_frame
	await get_tree().process_frame
	var aclarar: Tween = create_tween()
	aclarar.tween_property(_cortina, "modulate:a", 0.0, TIEMPO_FUNDIDO)
	await aclarar.finished
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ocupado = false


## true mientras hay un fundido en curso.
func ocupado() -> bool:
	return _ocupado
