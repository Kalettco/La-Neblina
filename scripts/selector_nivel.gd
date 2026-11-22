extends CanvasLayer
## "Continuar": lista de niveles ya desbloqueados. Al elegir uno se empieza
## con las habilidades que corresponden a ese nivel. Escape o "Volver" cierra.

signal cerrado

@onready var lista: VBoxContainer = $Menu/Caja/Lista
@onready var boton_volver: Button = $Menu/Caja/Volver


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	boton_volver.pressed.connect(cerrar)
	var maximo: int = Juego.cargar_progreso()
	for i in range(maximo + 1):
		var boton: Button = Button.new()
		boton.text = Juego.nombre_nivel(i) + _texto_habilidades(i)
		boton.pressed.connect(_elegir.bind(i))
		lista.add_child(boton)
	# El foco empieza en el último nivel alcanzado (lo más común es seguir ahí)
	var ultimo: Button = lista.get_child(lista.get_child_count() - 1) as Button
	if ultimo != null:
		ultimo.grab_focus()


func _texto_habilidades(indice: int) -> String:
	if indice >= Juego.NIVEL_CON_CAMPO:
		return "   (disparo + campo)"
	if indice >= Juego.NIVEL_CON_DISPARO:
		return "   (disparo)"
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		cerrar()


func _elegir(indice: int) -> void:
	for boton: Node in lista.get_children():
		(boton as Button).disabled = true
	Juego.continuar_partida(indice)


func cerrar() -> void:
	cerrado.emit()
	queue_free()
