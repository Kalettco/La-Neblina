extends RefCounted
## Datos de "Nivel 3 · Las raíces profundas" (PROVISIONAL).
## Nivel vacío con un cartel "En construcción" y una salida; se construye en la Fase 9.

const NOMBRE: String = "Nivel 3 · Las raíces profundas"
const SUBTITULO: String = "Acto 2 · En construcción"
const OBJETIVO: String = "Usa el disparo de luz y baja por las raíces hasta la grieta."


static func construir(n: Nivel) -> void:
	n.tamano(40, 18)
	n.zona(0, 40, "Raíces del Árbol Madre", 0.80, false)
	n.inicio(2, 13)
	n.suelo(0, 39, 14)
	n.cartel(6, 13, "En construcción: este nivel se arma en la Fase 9. Camina hasta la salida para continuar.")
	n.farol(10, 13)
	n.salida(36, 13)
