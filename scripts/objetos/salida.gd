extends Area2D
## Salida del sendero (fin del tutorial): arco de madera con flecha.
## Origen = centro inferior de la casilla.


func _ready() -> void:
	$Visual/Flecha.material = Efectos.material_sin_sombra()
	body_entered.connect(_al_entrar_cuerpo)


func _al_entrar_cuerpo(cuerpo: Node2D) -> void:
	if cuerpo is Jugador and not (cuerpo as Jugador).muerto:
		Juego.completar_nivel()
