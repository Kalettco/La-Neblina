extends RefCounted
## Datos del NIVEL 1 · EL SENDERO (tutorial).
## Coordenadas en casillas de 48 px. Ver los comandos en scripts/nivel.gd.

const NOMBRE: String = "Nivel 1 · El sendero"
const SUBTITULO: String = "Tutorial"
const OBJETIVO: String = "Aprende a usar la linterna y llega al final del sendero."


static func construir(n: Nivel) -> void:
	n.tamano(130, 18)
	n.zona(0, 18, "El sendero", 0.62, false)
	n.zona(18, 130, "El sendero", 0.80, false)
	n.inicio(2, 13)

	# 1. Caminar y saltar
	n.suelo(0, 22, 14)
	n.cartel(4, 13, "Usa A y D (o las flechas) para caminar. Salta con W, la flecha hacia arriba o Espacio.")
	n.bloque(10, 11, 13, 13)
	n.bloque(15, 16, 12, 13)

	# 2. Linterna y plataforma de luz
	n.cartel(18, 13, "Está muy oscuro. Mantén presionado el clic izquierdo (o F) para encender la linterna. Apunta con el mouse.")
	n.cartel(21, 13, "Sobre el agua hay una plataforma escondida. Ilumínala y salta encima: solo existe mientras la luz la toca.")
	n.agua(23, 29, 15)
	n.bloque(23, 29, 16, 17)
	n.plataforma_luz(25, 27, 12)

	# 3. La luz se gasta, frascos y faroles
	n.suelo(30, 95, 14)
	n.cartel(32, 13, "Mira la barra de LUZ arriba a la izquierda: baja mientras la linterna está encendida. Úsala solo cuando la necesites.")
	n.cartel(35, 13, "Toca los frascos para liberar luciérnagas. Cada una recarga parte de tu luz.")
	n.frasco(38, 13)
	n.farol(41, 13)
	n.cartel(44, 13, "Los faroles de piedra guardan tu progreso. Cerca del farol encendido, haz clic derecho para recargar tu luz. Si la luz llega a cero, la Bruma te regresa al último farol.")

	# 4. Sombras
	n.cartel(49, 13, "Una sombra de la Bruma. No puedes vencerla, pero le teme a la luz: apúntale para alejarla. Si te toca, pierdes luz.")
	n.sombra("patrulla", 56, 13, 52, 62)
	n.frasco(60, 13)

	# 5. Flor trampolín
	n.cartel(66, 13, "Esa pared es muy alta. Ilumina la flor para que se abra y camina sobre ella para salir disparada hacia arriba.")
	n.flor(69, 13)
	n.bloque(71, 72, 8, 13)
	n.farol(77, 13)

	# 6. Brasero y puerta
	n.cartel(80, 13, "Las raíces bloquean el camino. Ilumina el brasero hasta que se encienda para abrir el paso.")
	n.brasero(83, 13, "a")
	n.puerta(87, 8, 13, "a")

	# 7. Reto final del tutorial
	n.cartel(92, 13, "Dos plataformas escondidas seguidas. Mantén la luz encendida mientras saltas de una a otra.")
	n.agua(96, 106, 15)
	n.bloque(96, 106, 16, 17)
	n.plataforma_luz(98, 99, 12)
	n.plataforma_luz(102, 103, 11)
	n.frasco(103, 9)
	n.suelo(107, 129, 14)
	n.farol(108, 13)
	n.cartel(111, 13, "Otra sombra vigila el camino. Recuerda: la luz la aleja, pero también se gasta.")
	n.sombra("patrulla", 117, 13, 113, 122)
	n.frasco(119, 13)
	n.cartel(124, 13, "Aquí termina el sendero. Las huellas de papá siguen hacia el bosque profundo.")
	n.salida(127, 13)
