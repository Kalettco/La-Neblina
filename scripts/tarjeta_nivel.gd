extends Control
## Tarjeta al empezar cada nivel: nombre, subtítulo y objetivo.
## Enter o clic empieza el nivel (no antes de 0,35 s).

const TIEMPO_MINIMO: float = 0.35

@onready var nombre: Label = $Caja/Nombre
@onready var subtitulo: Label = $Caja/Subtitulo
@onready var objetivo: Label = $Caja/Objetivo
@onready var caja: Control = $Caja

var _espera: float = 0.0


func _ready() -> void:
	var datos: GDScript = Nivel.DATOS[clampi(Juego.nivel_actual, 0, Nivel.DATOS.size() - 1)]
	var constantes: Dictionary = datos.get_script_constant_map()
	nombre.text = constantes.get("NOMBRE", "")
	subtitulo.text = constantes.get("SUBTITULO", "")
	objetivo.text = "Objetivo: " + String(constantes.get("OBJETIVO", ""))
	caja.modulate.a = 0.0
	create_tween().tween_property(caja, "modulate:a", 1.0, 0.6)


func _process(delta: float) -> void:
	_espera += delta


func _unhandled_input(event: InputEvent) -> void:
	if _espera < TIEMPO_MINIMO or not Juego.es_avanzar(event):
		return
	get_viewport().set_input_as_handled()
	set_process_unhandled_input(false)
	Juego.ir_a_nivel(Juego.nivel_actual)
