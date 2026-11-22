class_name PantallaMuerte
extends CanvasLayer
## Oscurece la pantalla (0,6 s) y muestra el mensaje de muerte.
## Juego decide cuándo ocultarla (a los 1,5 s).

const TIEMPO_OSCURECER: float = 0.6
const TIEMPO_ACLARAR: float = 0.4

@onready var fondo: ColorRect = $Fondo
@onready var mensaje: Label = $Mensaje


func mostrar(texto: String) -> void:
	mensaje.text = texto
	fondo.modulate.a = 0.0
	mensaje.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(fondo, "modulate:a", 1.0, TIEMPO_OSCURECER)
	tween.tween_property(mensaje, "modulate:a", 1.0, TIEMPO_OSCURECER)


func ocultar() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(fondo, "modulate:a", 0.0, TIEMPO_ACLARAR)
	tween.tween_property(mensaje, "modulate:a", 0.0, TIEMPO_ACLARAR)
	tween.chain().tween_callback(queue_free)
