extends "res://scripts/objetos/plataforma_luz.gd"
## Cristal: como la plataforma de luz, pero SOLO aparece con el CAMPO de luz
## (la linterna normal no alcanza). Permanece mientras dura el campo + 1 s y se desvanece.
## Oculto: contorno muy tenue. Visible: celeste translúcido.
## Origen = centro inferior de la casilla; la pieza ocupa la mitad SUPERIOR.

const ALFA_OCULTO: float = 0.12


func _ready() -> void:
	tiempo_gracia = 1.0
	super._ready()


func _esta_iluminada() -> bool:
	for x: float in [-20.0, 0.0, 20.0]:
		if Juego.campo_ilumina(to_global(Vector2(x, CENTRO_Y))):
			return true
	return false


func _actualizar_aspecto(_delta: float) -> void:
	if _existe:
		visual.modulate.a = 1.0
		return
	var desvanecer: float = 1.0 - (_sin_luz - tiempo_gracia) / TIEMPO_DESVANECER
	visual.modulate.a = maxf(clampf(desvanecer, 0.0, 1.0), ALFA_OCULTO)
