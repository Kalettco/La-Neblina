class_name Tiras
extends RefCounted
## Ayudante para TODO el arte en tiras horizontales: cuadros del mismo tamaño, sin espacios.
## La cantidad de cuadros se calcula como ancho_imagen / ancho_cuadro.
## Si un archivo falta o sus medidas no cuadran, avisa y no hace nada:
## el objeto sigue usando su marcador de color.


## SpriteFrames vacío (sin la animación "default").
static func nuevas() -> SpriteFrames:
	var cuadros: SpriteFrames = SpriteFrames.new()
	cuadros.remove_animation("default")
	return cuadros


## Corta la tira ruta_png y la agrega a `cuadros` como la animación nombre_animacion.
## max_cuadros > 0 limita cuántos cuadros se usan.
## Devuelve false (sin tocar `cuadros`) si el archivo falta o sus medidas no sirven.
static func agregar(cuadros: SpriteFrames, ruta_png: String, ancho_cuadro: int, alto_cuadro: int,
		fps: float, se_repite: bool, nombre_animacion: String, max_cuadros: int = 0) -> bool:
	var tira: Texture2D = cargar(ruta_png, ancho_cuadro, alto_cuadro)
	if tira == null:
		return false
	@warning_ignore("integer_division")
	var cantidad: int = tira.get_width() / ancho_cuadro
	if max_cuadros > 0:
		cantidad = mini(cantidad, max_cuadros)
	if cuadros.has_animation(nombre_animacion):
		cuadros.clear(nombre_animacion)
	else:
		cuadros.add_animation(nombre_animacion)
	cuadros.set_animation_speed(nombre_animacion, fps)
	cuadros.set_animation_loop(nombre_animacion, se_repite)
	for i in range(cantidad):
		cuadros.add_frame(nombre_animacion, cuadro(tira, i, ancho_cuadro, alto_cuadro))
	return true


## Primer cuadro de una tira (por ejemplo, como textura de partículas). null si no sirve.
static func primer_cuadro(ruta_png: String, ancho_cuadro: int, alto_cuadro: int) -> AtlasTexture:
	var tira: Texture2D = cargar(ruta_png, ancho_cuadro, alto_cuadro)
	if tira == null:
		return null
	return cuadro(tira, 0, ancho_cuadro, alto_cuadro)


## Carga la tira y revisa sus medidas. Devuelve null (con aviso) si falta o no cuadra.
static func cargar(ruta_png: String, ancho_cuadro: int, alto_cuadro: int) -> Texture2D:
	if not ResourceLoader.exists(ruta_png):
		push_warning("Falta %s: se usa el marcador de color." % ruta_png)
		return null
	var tira: Texture2D = load(ruta_png) as Texture2D
	if tira == null:
		push_warning("No se pudo cargar %s: se usa el marcador de color." % ruta_png)
		return null
	var ancho: int = tira.get_width()
	var alto: int = tira.get_height()
	if alto != alto_cuadro or ancho < ancho_cuadro or ancho % ancho_cuadro != 0:
		push_warning("%s mide %d x %d: el alto debe ser %d y el ancho múltiplo de %d. Se usa el marcador de color." \
			% [ruta_png, ancho, alto, alto_cuadro, ancho_cuadro])
		return null
	return tira


## Cuadro número `indice` (desde 0) de la tira.
static func cuadro(tira: Texture2D, indice: int, ancho_cuadro: int, alto_cuadro: int) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = tira
	atlas.region = Rect2(indice * ancho_cuadro, 0, ancho_cuadro, alto_cuadro)
	return atlas


## Oculta (sin borrar) todos los hijos de `visual` menos `sprite`.
static func ocultar_marcador(visual: Node, sprite: Node) -> void:
	for hijo: Node in visual.get_children():
		if hijo != sprite and hijo is CanvasItem:
			(hijo as CanvasItem).visible = false
