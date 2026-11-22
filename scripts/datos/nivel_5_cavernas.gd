extends RefCounted
## Datos de "Nivel 5 · Las cavernas de cristal" (PROVISIONAL).
## Nivel vacío con un cartel "En construcción" y una salida; se construye en la Fase 11.

const NOMBRE: String = "Nivel 5 · Las cavernas de cristal"
const SUBTITULO: String = "Acto 2 · En construcción"
const OBJETIVO: String = "Cruza las cavernas usando el campo de luz."


static func construir(n: Nivel) -> void:
	n.tamano(40, 18)
	n.zona(0, 40, "Primeros cristales", 0.80, false)
	n.inicio(2, 13)
	n.suelo(0, 39, 14)
	n.cartel(6, 13, "En construcción: este nivel se arma en la Fase 11. Camina hasta la salida para continuar.")
	n.farol(10, 13)
	n.salida(36, 13)
