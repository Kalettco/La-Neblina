class_name Enemigo
extends Area2D
## Base de todos los enemigos: vida, daño recibido, muerte y daño por contacto.
## - Al recibir daño: parpadean en blanco 0,1 s y retroceden un poco.
## - Al llegar a 0 de vida: se deshacen en humo y sueltan una luciérnaga pequeña (+5 de luz).
## - La linterna los asusta pero NO les hace daño: el daño viene de la chispa (y del campo).
## Cada enemigo necesita un hijo "Visual" (Node2D).

const ESCENA_LUCIERNAGA: PackedScene = preload("res://escenas/objetos/luciernaga_pequena.tscn")
const TIEMPO_DESTELLO: float = 0.1
const FUERZA_RETROCESO: float = 180.0
const COLOR_HUMO: Color = Color(0.35, 0.25, 0.45)

@export var vida_maxima: int = 2
@export var dano_contacto: float = 25.0

@onready var visual: Node2D = $Visual

var vida: int = 0
var derrotado: bool = false
var _destello: float = 0.0
var _retroceso: Vector2 = Vector2.ZERO


func _ready() -> void:
	vida = vida_maxima
	add_to_group("enemigos")


## Centro del cuerpo (para apuntar, iluminar y soltar la luciérnaga).
func centro() -> Vector2:
	return global_position


## La llaman la chispa y el campo de luz.
func recibir_dano(cantidad: int, desde: Vector2) -> void:
	if derrotado:
		return
	vida -= cantidad
	_destello = TIEMPO_DESTELLO
	var direccion: Vector2 = (centro() - desde).normalized()
	_retroceso = direccion * FUERZA_RETROCESO
	Audio.sfx_impacto()
	if vida <= 0:
		morir()


func morir() -> void:
	if derrotado:
		return
	derrotado = true
	Juego.registrar_sombra_destruida()
	Audio.sfx_enemigo_muere()
	Efectos.estallido(get_parent(), centro(), COLOR_HUMO, 30)
	var luciernaga: Node2D = ESCENA_LUCIERNAGA.instantiate()
	luciernaga.position = centro()
	get_parent().add_child.call_deferred(luciernaga)
	queue_free()


## Lía reaparece: el enemigo vuelve a su estado inicial (cada tipo lo amplía).
func reiniciar() -> void:
	_retroceso = Vector2.ZERO
	_destello = 0.0


## Puede hacer daño ahora mismo (por ejemplo, no si está asustado).
func puede_danar() -> bool:
	return not derrotado


## Llamar cada cuadro desde _physics_process de cada enemigo.
func procesar_comunes(delta: float) -> void:
	# Retroceso por golpe
	if _retroceso != Vector2.ZERO:
		global_position += _retroceso * delta
		_retroceso = _retroceso.move_toward(Vector2.ZERO, 900.0 * delta)
	# Parpadeo blanco al recibir daño
	_destello = maxf(_destello - delta, 0.0)
	var brillo: float = 3.0 if _destello > 0.0 else 1.0
	visual.modulate = Color(brillo, brillo, brillo, visual.modulate.a)
	# Daño por contacto
	var jugador: Jugador = Juego.jugador
	if is_instance_valid(jugador) and puede_danar() and not jugador.muerto and overlaps_body(jugador):
		jugador.recibir_dano(dano_contacto, global_position.x)
