extends CanvasLayer
## Menú de pausa (Escape): botones Continuar, Reiniciar nivel, Configuración, Menú principal.
## También responde a atajos: Enter/Escape continuar · R reiniciar · Q menú.

const ESCENA_CONFIGURACION: PackedScene = preload("res://escenas/ui/pantalla_configuracion.tscn")

@onready var datos: Label = $Menu/Caja/Datos
@onready var caja: Control = $Menu/Caja
@onready var boton_continuar: Button = $Menu/Caja/Botones/Continuar
@onready var boton_reiniciar: Button = $Menu/Caja/Botones/Reiniciar
@onready var boton_configuracion: Button = $Menu/Caja/Botones/Configuracion
@onready var boton_menu: Button = $Menu/Caja/Botones/MenuPrincipal

var _configurando: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # debe funcionar con el juego pausado
	visible = false
	boton_continuar.pressed.connect(_continuar)
	boton_reiniciar.pressed.connect(_reiniciar)
	boton_configuracion.pressed.connect(_configurar)
	boton_menu.pressed.connect(_ir_al_menu)


func _unhandled_input(event: InputEvent) -> void:
	if _configurando:
		return
	if event.is_action_pressed("pausa"):
		if visible:
			_continuar()
		elif not Juego.muriendo and not Juego.nivel_terminado:
			_abrir()
		get_viewport().set_input_as_handled()
		return
	if not visible or not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_R:
			_reiniciar()
		KEY_Q:
			_ir_al_menu()
		_:
			return
	get_viewport().set_input_as_handled()


func _abrir() -> void:
	datos.text = "Tiempo de juego: %s    ·    Veces que la Bruma te alcanzó: %d" % [
		Juego.tiempo_texto(), Juego.estadisticas["muertes"]]
	visible = true
	get_tree().paused = true
	boton_continuar.grab_focus()


func _continuar() -> void:
	visible = false
	get_tree().paused = false


func _reiniciar() -> void:
	Juego.ir_a_nivel(Juego.nivel_actual)


func _ir_al_menu() -> void:
	Juego.ir_al_menu()


func _configurar() -> void:
	_configurando = true
	caja.visible = false
	var configuracion: Node = ESCENA_CONFIGURACION.instantiate()
	configuracion.cerrado.connect(_al_cerrar_configuracion)
	add_child(configuracion)


func _al_cerrar_configuracion() -> void:
	_configurando = false
	caja.visible = true
	boton_configuracion.grab_focus()
