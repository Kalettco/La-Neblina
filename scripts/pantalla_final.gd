extends Control
## Pantalla final con las estadísticas de la partida.
## Enter o clic vuelve al menú (no antes de 0,8 s, para no saltarla sin querer).

const TIEMPO_MINIMO: float = 0.8

@onready var estadisticas: Label = $Caja/Estadisticas
@onready var caja: Control = $Caja

var _espera: float = 0.0


func _ready() -> void:
	var datos: Dictionary = Juego.estadisticas
	var liberadas: int = 0
	var total: int = 0
	for i in range(datos["luciernagas_total"].size()):
		liberadas += datos["luciernagas_liberadas"][i]
		total += datos["luciernagas_total"][i]
	estadisticas.text = "\n".join([
		"Tiempo de juego: %s" % Juego.tiempo_texto(),
		"Luciérnagas liberadas: %d de %d" % [liberadas, total],
		"Luciérnagas guardianas: %d de 3" % datos["guardianas"],
		"Veces que la Bruma te alcanzó: %d" % datos["muertes"],
		"Sombras destruidas: %d" % datos["sombras_destruidas"],
	])
	caja.modulate.a = 0.0
	create_tween().tween_property(caja, "modulate:a", 1.0, 1.0)


func _process(delta: float) -> void:
	_espera += delta


func _unhandled_input(event: InputEvent) -> void:
	if _espera < TIEMPO_MINIMO or not Juego.es_avanzar(event):
		return
	get_viewport().set_input_as_handled()
	set_process_unhandled_input(false)
	Juego.ir_al_menu()
