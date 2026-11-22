extends RefCounted
## Datos del NIVEL 2 · EL CORAZÓN DEL BOSQUE (nivel completo).
## Victoria: rescatar las 3 guardianas y entregar la luz al Árbol Madre.
## Coordenadas en casillas de 48 px. Ver los comandos en scripts/nivel.gd.

const NOMBRE: String = "Nivel 2 · El corazón del bosque"
const SUBTITULO: String = "Nivel completo"
const OBJETIVO: String = "Rescata a las 3 luciérnagas guardianas y llega al Árbol Madre para salvar a tu papá."


static func construir(n: Nivel) -> void:
	n.tamano(252, 22)
	n.zona(0, 86, "Zona 1 · La quebrada", 0.80, false)
	n.zona(86, 171, "Zona 2 · La cueva", 0.88, true)
	n.zona(171, 207, "Zona 3 · La copa de los árboles", 0.80, false)
	n.zona(207, 252, "Zona 4 · El Árbol Madre", 0.85, false)
	n.inicio(2, 17)

	# Zona 1: la quebrada
	n.suelo(0, 12, 18)
	n.nota(4, 17, "Nota de papá: \"La Bruma sale del Árbol Madre. Las tres luciérnagas guardianas pueden sanarlo.\"")
	n.farol(7, 17)
	n.agua(13, 30, 19)
	n.bloque(13, 30, 20, 21)
	n.plataforma_luz(15, 16, 16)
	n.plataforma_luz(19, 20, 15)
	n.plataforma_luz(23, 24, 16)
	n.plataforma_luz(27, 28, 15)
	n.frasco(20, 13)
	n.suelo(31, 49, 18)
	n.nota(33, 17, "Nota de papá: \"Las sombras no mueren. Solo se apartan de la luz.\"")
	n.sombra("patrulla", 40, 17, 35, 45)
	n.frasco(43, 17)
	n.plataforma_luz(46, 47, 15)
	n.bloque(50, 62, 12, 21)
	n.farol(52, 11)
	n.nota(54, 11, "Nota de papá: \"Los braseros viejos todavía abren los pasos de raíces.\"")
	n.brasero(56, 11, "a")
	n.puerta(59, 6, 11, "a")
	n.guardiana(61, 11)                                   # GUARDIANA 1
	n.suelo(63, 94, 18)
	n.nota(67, 17, "Nota de papá: \"Las flores nocturnas se abren con la luz y te impulsan hacia arriba.\"")
	n.frasco(70, 17)
	n.flor(73, 17)
	n.bloque(75, 76, 11, 17)
	n.frasco(81, 17)

	# Zona 2: la cueva (techo de roca)
	n.bloque(86, 170, 0, 9)
	n.farol(89, 17)
	n.nota(91, 17, "Nota de papá: \"En la cueva la oscuridad pesa más. No gastes la luz sin necesidad.\"")
	n.suelo(95, 104, 18)
	n.espinas(95, 104, 17)
	n.plataforma_luz(96, 97, 15)
	n.plataforma_luz(99, 100, 14)
	n.plataforma_luz(102, 103, 15)
	n.frasco(100, 12)
	n.suelo(105, 126, 18)
	n.sombra("patrulla", 110, 17, 106, 116)
	n.frasco(114, 17)
	n.brasero(119, 17, "b")
	n.sombra("cazadora", 123, 17, 112, 125)
	n.puerta(126, 10, 17, "b")
	n.suelo(127, 144, 18)
	n.nota(128, 17, "Nota de papá: \"Vi una luciérnaga guardiana en lo alto de la cueva.\"")
	n.farol(130, 17)
	n.flor(132, 17)
	n.bloque(134, 138, 12, 12)
	n.guardiana(136, 11)                                  # GUARDIANA 2
	n.agua(145, 155, 19)
	n.bloque(145, 155, 20, 21)
	n.plataforma_luz(147, 148, 16)
	n.plataforma_luz(151, 152, 15)
	n.sombra("cazadora", 151, 13, 146, 156)
	n.suelo(156, 185, 18)
	n.frasco(160, 17)
	n.farol(165, 17)

	# Zona 3: la copa de los árboles
	n.nota(176, 17, "Nota de papá: \"Subí por el tronco del higuerón para cruzar el barranco de espinas.\"")
	n.bloque(186, 187, 4, 21)              # tronco
	n.bloque(181, 182, 15, 15)             # rama sólida
	n.plataforma_luz(184, 185, 12)
	n.plataforma_luz(181, 182, 9)
	n.bloque(184, 185, 6, 6)               # rama sólida
	n.farol(187, 3)
	n.suelo(188, 206, 20)
	n.espinas(188, 206, 19)
	n.plataforma_luz(190, 191, 4)
	n.plataforma_luz(194, 195, 5)
	n.plataforma_luz(198, 199, 4)
	n.frasco(195, 2)
	n.sombra("cazadora", 196, 2, 189, 201)
	n.bloque(202, 206, 4, 4)
	n.farol(203, 3)
	n.guardiana(205, 3)                                   # GUARDIANA 3

	# Zona 4: el Árbol Madre
	n.suelo(207, 251, 18)
	n.farol(210, 17)
	n.nota(213, 17, "Nota de papá: \"Si llegas hasta aquí, Lía, recuerda lo que decía la abuela: la luz no es para guardarla.\"")
	n.frasco(218, 17)
	n.sombra("patrulla", 225, 17, 217, 234)
	n.sombra("cazadora", 222, 15, 214, 236)
	n.sombra("cazadora", 231, 17, 218, 237)
	n.frasco(232, 17)
	n.arbol(245, 17)
