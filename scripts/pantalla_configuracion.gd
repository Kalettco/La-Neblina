extends CanvasLayer
## Configuración: pantalla completa / ventana, tamaño de ventana y sonido.
## Cada botón cambia la opción al hacer clic (o Enter). Escape o "Volver" cierra.

signal cerrado

@onready var boton_pantalla: Button = $Menu/Caja/Pantalla
@onready var boton_tamano: Button = $Menu/Caja/Tamano
@onready var boton_sonido: Button = $Menu/Caja/Sonido
@onready var boton_volver: Button = $Menu/Caja/Volver


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	boton_pantalla.pressed.connect(_al_cambiar_pantalla)
	boton_tamano.pressed.connect(_al_cambiar_tamano)
	boton_sonido.pressed.connect(_al_cambiar_sonido)
	boton_volver.pressed.connect(cerrar)
	_actualizar_textos()
	boton_pantalla.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		cerrar()


func cerrar() -> void:
	cerrado.emit()
	queue_free()


func _al_cambiar_pantalla() -> void:
	Configuracion.alternar_pantalla_completa()
	_actualizar_textos()


func _al_cambiar_tamano() -> void:
	Configuracion.siguiente_tamano()
	_actualizar_textos()


func _al_cambiar_sonido() -> void:
	Configuracion.siguiente_modo_sonido()
	_actualizar_textos()


func _actualizar_textos() -> void:
	boton_pantalla.text = "Pantalla: " + ("Completa" if Configuracion.pantalla_completa else "En ventana")
	boton_tamano.text = "Tamaño de ventana: " + Configuracion.NOMBRES_TAMANO[Configuracion.tamano]
	# El tamaño solo se usa en modo ventana
	boton_tamano.disabled = Configuracion.pantalla_completa
	boton_sonido.text = "Sonido: " + Configuracion.MODOS_SONIDO[Configuracion.modo_sonido]
