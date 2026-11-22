class_name Efectos
extends RefCounted
## Utilidades visuales compartidas (texturas de luz y partículas) mientras no hay arte.

static var _textura_radial: GradientTexture2D = null
static var _material_sin_sombra: CanvasItemMaterial = null


## Degradado radial blanco -> transparente, 256x256 (radio 128 px con escala 1).
static func textura_radial() -> GradientTexture2D:
	if _textura_radial == null:
		var degradado: Gradient = Gradient.new()
		degradado.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		degradado.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		_textura_radial = GradientTexture2D.new()
		_textura_radial.gradient = degradado
		_textura_radial.fill = GradientTexture2D.FILL_RADIAL
		_textura_radial.fill_from = Vector2(0.5, 0.5)
		_textura_radial.fill_to = Vector2(1.0, 0.5)
		_textura_radial.width = 256
		_textura_radial.height = 256
	return _textura_radial


## Escala para que textura_radial() alcance el radio pedido en px.
static func escala_para_radio(radio: float) -> float:
	return radio / 128.0


## Material que ignora la oscuridad (se ve brillante aunque esté de noche).
static func material_sin_sombra() -> CanvasItemMaterial:
	if _material_sin_sombra == null:
		_material_sin_sombra = CanvasItemMaterial.new()
		_material_sin_sombra.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _material_sin_sombra


## Estallido de partículas de un solo uso; se borra solo al terminar.
static func estallido(padre: Node, posicion: Vector2, color: Color, cantidad: int = 24) -> void:
	var particulas: CPUParticles2D = CPUParticles2D.new()
	particulas.material = material_sin_sombra()
	particulas.one_shot = true
	particulas.explosiveness = 0.9
	particulas.amount = cantidad
	particulas.lifetime = 0.9
	particulas.direction = Vector2(0.0, -1.0)
	particulas.spread = 180.0
	particulas.initial_velocity_min = 60.0
	particulas.initial_velocity_max = 200.0
	particulas.gravity = Vector2(0.0, -60.0)
	particulas.damping_min = 80.0
	particulas.damping_max = 120.0
	particulas.scale_amount_min = 4.0
	particulas.scale_amount_max = 7.0
	particulas.color = color
	padre.add_child(particulas)
	particulas.global_position = posicion
	particulas.emitting = true
	padre.get_tree().create_timer(particulas.lifetime + 0.3).timeout.connect(particulas.queue_free)
