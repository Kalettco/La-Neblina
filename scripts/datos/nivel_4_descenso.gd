extends RefCounted
## Datos del NIVEL 4 · EL DESCENSO (acto 2).
## VERTICAL (48 x 140 casillas): se avanza hacia ABAJO por una grieta.
## Coordenadas en casillas de 48 px. Ver los comandos en scripts/nivel.gd.
##
## Reglas usadas: salientes de 1 casilla de grosor separados 6 filas (5 libres para
## saltar); huecos de 2 casillas; espinas de 2-3 casillas solo donde hay techo alto;
## un farol cada 22-25 filas (el último tramo es una caída libre sin peligros).
##
## Recorrido:
##   1 La grieta: salientes alternados (izquierda/derecha), espinas y murciélagos.
##   2 Cascada subterránea: corriente de aire con lanzadoras en las paredes y un
##     puente de plataformas que caen sobre espinas.
##   3 Raíces colgantes: plataformas de luz en zigzag y un brasero lejano que se
##     enciende disparando; abre una puerta de raíces en el suelo.
##   4 El fondo: arena con plataformas fijas y el gólem de bruma (barra de vida en el HUD);
##     durante la pelea aparecen luciérnagas que recargan luz. Al vencerlo aparece la
##     Luciérnaga Reina.

const NOMBRE: String = "Nivel 4 · El descenso"
const SUBTITULO: String = "Acto 2"
const OBJETIVO: String = "Desciende por la grieta hasta el fondo."


static func construir(n: Nivel) -> void:
	n.tamano(48, 140)
	n.zona_vertical(0, 32, "Zona 1 · La grieta", 0.85, true)
	n.zona_vertical(32, 60, "Zona 2 · Cascada subterránea", 0.85, true)
	n.zona_vertical(60, 106, "Zona 3 · Raíces colgantes", 0.88, true)
	n.zona_vertical(106, 140, "Zona 4 · El fondo", 0.88, true)
	n.inicio(8, 4)

	# --- Paredes de la grieta (interior: columnas 6 a 41) ---
	n.bloque(0, 5, 0, 139)                     # pared izquierda
	n.bloque(42, 47, 0, 42)                    # pared derecha (con un hueco para una lanzadora)
	n.bloque(45, 47, 43, 46)
	n.bloque(42, 47, 47, 139)
	n.bloque(6, 41, 0, 0)                      # techo

	# --- Zona 1: La grieta (salientes alternados, espinas y murciélagos) ---
	n.bloque(6, 22, 5, 5)                      # saliente 1 (inicio)
	n.farol(10, 4)
	n.cartel(14, 4, "La grieta baja hasta el fondo. Déjate caer de saliente en saliente: la caída no hace daño, pero las espinas sí.")
	n.nota_raiz(19, 4, "La voz del Árbol: \"En la grieta viven murciélagos de la Bruma. Son frágiles: una sola chispa basta.\"")
	n.bloque(14, 41, 11, 11)                   # saliente 2 (se baja por la izquierda)
	n.espinas(19, 20, 10)
	n.murcielagos(35, 8, 3)
	n.frasco(40, 10)
	n.bloque(6, 30, 17, 17)                    # saliente 3 (se baja por la derecha)
	n.frasco(7, 16)
	n.espinas(20, 22, 16)
	n.murcielagos(24, 14, 3)
	n.bloque(18, 41, 23, 23)                   # saliente 4 (se baja por la izquierda)
	n.espinas(25, 26, 22)
	n.murcielagos(36, 20, 4)
	n.frasco(40, 22)
	n.bloque(6, 30, 29, 29)                    # saliente 5 (se baja por la derecha, a la corriente)
	n.farol(13, 28)
	n.espinas(20, 21, 28)
	n.cartel(26, 28, "Abajo sopla una corriente de aire que frena la caída. Mientras bajas, dispárales a las lanzadoras de las paredes.")

	# --- Zona 2: Cascada subterránea (corriente, lanzadoras, plataformas que caen) ---
	n.bloque(6, 27, 30, 45)                    # roca bajo el saliente 5
	n.bloque(28, 30, 30, 36)                   # (con un hueco para una lanzadora)
	n.bloque(28, 30, 41, 45)
	n.lanzadora(29, 40)                        # en el hueco de la pared izquierda
	n.lanzadora(43, 46)                        # en el hueco de la pared derecha
	n.corriente(31, 41, 33, 49)
	n.bloque(31, 41, 52, 58)                   # repisa de llegada
	n.farol(39, 51)
	n.cartel(35, 51, "Las plataformas de raíz se caen poco después de pisarlas. ¡No te detengas!")
	n.bloque(14, 30, 57, 58)                   # fondo del foso
	n.espinas(14, 30, 56)
	n.plataforma_cae(26, 52)                   # puente de plataformas que caen (huecos de 2)
	n.plataforma_cae(21, 52)
	n.plataforma_cae(16, 52)
	n.bloque(9, 13, 52, 58)                    # repisa del otro lado
	n.frasco(11, 51)
	n.bloque(9, 41, 59, 69)                    # roca; a la izquierda queda la hendidura (columnas 6 a 8)

	# --- Zona 3: Raíces colgantes (plataformas de luz en zigzag y brasero lejano) ---
	n.bloque(6, 14, 74, 104)                   # columna de roca donde se aterriza
	n.farol(8, 73)
	n.cartel(12, 73, "Raíces colgantes: las plataformas de luz bajan en zigzag. Ilumínalas con la linterna antes de saltar.")
	n.plataforma_luz(17, 18, 77)
	n.plataforma_luz(21, 22, 80)
	n.plataforma_luz(25, 26, 83)
	n.plataforma_luz(29, 30, 86)
	n.bloque(33, 35, 89, 99)                   # repisa con un hueco tapado por raíces
	n.bloque(39, 41, 89, 90)
	n.puerta_suelo(36, 38, 89, "b")
	n.cartel(34, 88, "Las raíces tapan el hueco. Abajo a la izquierda hay un brasero: dispárale tres chispas para abrir el paso.")
	n.farol(40, 88)
	n.bloque(19, 20, 93, 93)                   # repisa del brasero (lejos: la linterna no llega)
	n.brasero(19, 92, "b")
	n.bloque(15, 32, 98, 99)                   # foso de espinas bajo las plataformas
	n.espinas(15, 32, 97)
	n.bloque(6, 35, 100, 111)                  # roca; el hueco (columnas 36 a 38) baja al fondo
	n.bloque(39, 41, 91, 111)

	# --- Zona 4: El fondo (arena con el gólem y la Luciérnaga Reina) ---
	n.suelo(6, 41, 131)
	n.farol(39, 130)
	n.frasco(41, 130)
	n.cartel(35, 130, "Gólem de bruma: su coraza solo se ablanda con luz. Ilumínalo con la linterna (clic izquierdo) mientras le disparas (clic derecho). Cuando levante los brazos, ¡salta!")
	n.puerta_arena(32, 120, 130, "fondo")      # se cierra detrás de Lía
	# Plataformas fijas para esquivar la onda del gólem (cada una 3 filas más alta):
	# escalones a los lados, dos repisas medias y una alta en el centro.
	# El gólem (4 filas de alto) camina entre las columnas 11 y 26: nunca toca los escalones
	# y pasa por debajo de las repisas sin alcanzar a Lía.
	n.bloque(7, 9, 128, 128)
	n.bloque(28, 30, 128, 128)
	n.bloque(11, 14, 125, 125)
	n.bloque(23, 26, 125, 125)
	n.bloque(17, 20, 122, 122)
	n.arena(7, 30, "fondo", [
		[["golem", 18, 130, 11, 26], ["frasco", 8, 127], ["frasco", 18, 121]],
	], 112, 130, 5.0)                          # una luciérnaga suelta cada 5 s (+12 de luz)
	n.reina(18, 130, "fondo")                  # aparece al vencer al gólem
