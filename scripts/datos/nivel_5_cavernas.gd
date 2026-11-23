extends RefCounted
## Datos del NIVEL 5 · LAS CAVERNAS DE CRISTAL (acto 2).
## Mixto (220 x 40 casillas): baja al río y termina con una subida larga.
## Oscuridad máxima (#0a0a12): la linterna sola apenas alcanza. Enseña el CAMPO DE LUZ.
## Coordenadas en casillas de 48 px. Ver los comandos en scripts/nivel.gd.
##
## Reglas usadas: huecos de 2 casillas y subidas de 1 a 3 filas; cada tramo de cristales
## se cruza en menos de 3 s (el campo dura 4 s + 1 s de los cristales) y antes de cada
## tramo nuevo hay suelo firme para esperar los 10 s de recarga. Un farol cada 24-28 casillas.
##
## Recorrido:
##   1 Primeros cristales: carteles del campo; dos abismos que solo se cruzan con cristales.
##   2 Río negro: plataformas de luz (linterna) y cristales (campo) sobre agua.
##   3 Nido de murciélagos: enjambres de 5 y 6; el pulso del campo los deshace en grupo.
##   4 El umbral: un gólem guarda la subida; ledges y cristales hasta la salida, arriba.

const NOMBRE: String = "Nivel 5 · Las cavernas de cristal"
const SUBTITULO: String = "Acto 2"
const OBJETIVO: String = "Cruza las cavernas usando el campo de luz."


static func construir(n: Nivel) -> void:
	n.tamano(220, 40)
	n.zona(0, 55, "Zona 1 · Primeros cristales", 0.95, true)
	n.zona(55, 110, "Zona 2 · Río negro", 0.95, true)
	n.zona(110, 160, "Zona 3 · Nido de murciélagos", 0.95, true)
	n.zona(160, 220, "Zona 4 · El umbral", 0.95, true)
	n.inicio(2, 29)

	# --- Zona 1: Primeros cristales (enseña el campo de luz) ---
	n.bloque(0, 54, 0, 15)                     # techo
	n.suelo(0, 14, 30)
	n.farol(4, 29)
	n.cartel(7, 29, "La Luciérnaga Reina te dio el CAMPO DE LUZ: presiona Q (o clic izquierdo y derecho a la vez). Todo a tu alrededor brilla 4 s. Gasta 15 de luz y tarda 10 s en recargarse.")
	n.cartel(12, 29, "Los cristales solo aparecen con el campo de luz. Úsalo frente al abismo y cruza antes de que se apaguen.")
	n.agua(15, 24, 33)                         # abismo 1 (plano)
	n.bloque(15, 24, 34, 39)
	n.cristal(17, 18, 30)
	n.cristal(21, 22, 30)
	n.suelo(25, 34, 30)
	n.frasco(27, 29)
	n.cartel(31, 29, "El campo necesita recargarse: mira el ícono junto a tu barra de luz. Cuando brille, úsalo otra vez.")
	n.agua(35, 44, 33)                         # abismo 2 (sube en escalera)
	n.bloque(35, 44, 34, 39)
	n.cristal(37, 38, 28)
	n.cristal(41, 42, 26)
	n.suelo(45, 54, 27)
	n.farol(47, 26)
	n.cartel(52, 26, "El río negro. Las plataformas de luz se ven con la linterna; los cristales, solo con el campo. Guarda el campo para cuando no haya otra salida.")

	# --- Zona 2: Río negro (plataformas de luz y cristales sobre el agua) ---
	n.bloque(55, 109, 0, 13)                   # techo
	n.agua(55, 104, 33)
	n.bloque(55, 104, 34, 39)
	n.plataforma_luz(57, 58, 27)               # tramo 1: solo linterna
	n.plataforma_luz(61, 62, 26)
	n.bloque(65, 68, 27, 39)                   # islote 1
	n.frasco(66, 26)
	n.cristal(71, 72, 26)                      # tramo 2: solo campo
	n.cristal(75, 76, 25)
	n.cristal(79, 80, 26)
	n.bloque(83, 86, 27, 39)                   # islote 2 (aquí se espera la recarga)
	n.farol(84, 26)
	n.cartel(86, 26, "Espera a que el campo se recargue. Más adelante los cristales y las plataformas de luz se mezclan: con el campo encendido se ven todos.")
	n.plataforma_luz(89, 90, 26)               # tramo 3: mezclado
	n.cristal(93, 94, 25)
	n.plataforma_luz(97, 98, 26)
	n.cristal(101, 102, 27)

	# --- Zona 3: Nido de murciélagos (enjambres grandes) ---
	n.suelo(105, 159, 27)
	n.bloque(110, 159, 0, 12)                  # techo
	n.farol(108, 26)
	n.cartel(112, 26, "Un nido de murciélagos. Si te rodean, usa el campo de luz: su pulso los deshace a todos a la vez.")
	n.murcielagos(122, 20, 5)
	n.frasco(128, 26)
	n.bloque(131, 133, 24, 26)                 # roca para saltar
	n.farol(132, 23)
	n.murcielagos(140, 19, 6)
	n.espinas(144, 146, 26)
	n.murcielagos(152, 20, 6)
	n.frasco(156, 26)

	# --- Zona 4: El umbral (gólem y subida larga con cristales) ---
	n.bloque(160, 219, 0, 1)                   # techo alto
	n.suelo(160, 219, 27)
	n.farol(161, 26)
	n.cartel(163, 26, "El umbral. Un gólem guarda la subida. El campo de luz le disuelve la coraza: úsalo y dispárale mientras dura.")
	n.golem(176, 26, 167, 183)                 # no alcanza el farol ni los salientes
	n.frasco(186, 26)
	n.bloque(187, 190, 24, 24)                 # salientes fijos
	n.bloque(193, 196, 21, 21)
	n.frasco(195, 20)
	n.cristal(199, 200, 18)                    # cristales de la subida
	n.cristal(203, 204, 15)
	n.bloque(207, 211, 12, 12)
	n.farol(209, 11)
	n.bloque(214, 216, 9, 9)
	n.bloque(217, 219, 6, 6)
	n.salida(218, 5)
