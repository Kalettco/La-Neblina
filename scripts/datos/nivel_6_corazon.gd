extends RefCounted
## Datos del NIVEL 6 · EL CORAZÓN DE LA BRUMA (acto 2, último nivel).
## 180 x 40 casillas: baja por escalones, cruza las fauces, vence 3 oleadas y
## termina en la arena del jefe final (40 x 22 casillas).
## Coordenadas en casillas de 48 px. Ver los comandos en scripts/nivel.gd.
##
## Recorrido:
##   1 Camino de raíces muertas: escalones hacia abajo con todos los enemigos mezclados.
##   2 Las fauces: pasillo con 5 pares de paredes que se cierran por turnos.
##   3 Arena de oleadas: 3 oleadas; entre una y otra aparecen 2 frascos; luciérnagas sueltas.
##   4 El Devorador de Luz: 4 salientes y 4 cristales; farol a la entrada; 2 lámparas
##     que recargan luz sobre los salientes bajos. Durante la pelea el campo de luz (Q)
##     no necesita recargarse.
##     Al vencerlo aparece el alma de Andrés -> historia final.

const NOMBRE: String = "Nivel 6 · El corazón de la Bruma"
const SUBTITULO: String = "Acto 2 · Final"
const OBJETIVO: String = "Recupera el alma de papá."


static func construir(n: Nivel) -> void:
	n.tamano(180, 40)
	n.zona(0, 46, "Zona 1 · Camino de raíces muertas", 0.88, true)
	n.zona(46, 83, "Zona 2 · Las fauces", 0.88, true)
	n.zona(83, 135, "Zona 3 · Arena de oleadas", 0.88, true)
	n.zona(135, 180, "Zona 4 · El Devorador de Luz", 0.95, true)
	n.inicio(2, 9)

	# --- Zona 1: Camino de raíces muertas (descenso con enemigos mezclados) ---
	n.bloque(0, 45, 0, 3)                      # techo
	n.suelo(0, 10, 10)
	n.farol(3, 9)
	n.cartel(7, 9, "El corazón de la Bruma. Aquí abajo te esperan todas sus criaturas a la vez.")
	n.suelo(11, 18, 14)                        # escalón 1
	n.sombra("patrulla", 15, 13, 12, 18)
	n.frasco(17, 13)
	n.suelo(19, 27, 18)                        # escalón 2
	n.espinas(22, 23, 17)
	n.lanzadora(25, 13)
	n.suelo(28, 36, 22)                        # escalón 3
	n.farol(29, 21)
	n.nota_raiz(32, 21, "La voz del Árbol: \"Tu papá está cerca, pequeña. Usa todo lo que aprendiste.\"")
	n.murcielagos(35, 18, 4)
	n.suelo(37, 45, 26)                        # escalón 4
	n.sombra("cazadora", 41, 25, 38, 45)
	n.frasco(44, 25)

	# --- Zona 2: Las fauces (paredes que se cierran por turnos) ---
	n.suelo(46, 179, 30)                       # suelo de aquí hasta el jefe
	n.bloque(46, 82, 0, 21)                    # techo del pasillo (filas libres 22 a 29)
	n.farol(48, 29)
	n.cartel(50, 29, "Las fauces de la Bruma. Tiemblan antes de cerrarse: cruza justo cuando se abran.")
	n.fauces(53, 22, 29, 2, 0.0)
	n.fauces(59, 22, 29, 2, 0.25)
	n.fauces(65, 22, 29, 2, 0.5)
	n.frasco(68, 29)
	n.fauces(71, 22, 29, 2, 0.75)
	n.fauces(77, 22, 29, 2, 0.4)

	# --- Zona 3: Arena de oleadas ---
	n.bloque(83, 134, 0, 14)                   # techo (filas libres 15 a 29)
	n.farol(85, 29)
	n.cartel(88, 29, "La última puerta de la Bruma: tres oleadas. Si te quedas sin luz, dispárale a este farol desde la arena: te devuelve luz.")
	n.puerta_arena(92, 15, 29, "oleadas")      # entrada: se cierra al entrar
	n.bloque(96, 98, 27, 27)                   # salientes para esquivar al gólem
	n.bloque(126, 128, 27, 27)
	n.arena(92, 129, "oleadas", [
		[["murcielagos", 110, 22, 4], ["sombra", "patrulla", 100, 29], ["sombra", "patrulla", 120, 29]],
		[["lanzadora", 104, 24], ["lanzadora", 118, 24], ["sombra", "cazadora", 108, 29],
		 ["sombra", "cazadora", 122, 29], ["frasco", 97, 26], ["frasco", 127, 26]],
		[["golem", 112, 29, 102, 121], ["murcielagos", 100, 22, 4], ["frasco", 97, 26], ["frasco", 127, 26]],
	], 15, 29, 6.0)
	n.puerta_arena(130, 15, 29, "oleadas", true)   # salida: abre al vencer
	n.farol(132, 29)                           # punto de control antes del jefe
	n.cartel(134, 29, "El Devorador de Luz. Solo le duele el ojo, y solo lo abre después de atacar. Ilumínalo con la linterna mientras le disparas: el daño es doble.")

	# --- Zona 4: El Devorador de Luz (arena de 40 x 22) ---
	n.bloque(135, 179, 0, 8)                   # techo
	n.bloque(176, 179, 9, 29)                  # pared derecha
	n.puerta_arena(135, 9, 29, "jefe")         # se cierra cuando despierta el jefe
	n.bloque(140, 143, 27, 27)                 # salientes bajos (esquivar la embestida)
	n.bloque(168, 171, 27, 27)
	n.lampara(141, 26)                         # lámparas que recargan la luz (una en cada lado)
	n.lampara(170, 26)
	n.bloque(146, 149, 24, 24)                 # salientes altos
	n.bloque(162, 165, 24, 24)
	n.cristal(151, 152, 21)                    # cristales (solo con el campo de luz)
	n.cristal(159, 160, 21)
	n.cristal(154, 155, 18)
	n.cristal(156, 157, 18)
	n.jefe(136, 175, 9, 29)
