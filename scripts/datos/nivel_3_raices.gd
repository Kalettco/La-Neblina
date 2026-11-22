extends RefCounted
## Datos del NIVEL 3 · LAS RAÍCES PROFUNDAS (acto 2).
## Horizontal, bajo tierra. Enseña el disparo de luz y termina en una arena.
## Coordenadas en casillas de 48 px. Ver los comandos en scripts/nivel.gd.
##
## Reglas usadas: salto de hasta 3,5 casillas de alto y huecos de 2-3 casillas;
## un farol cada 25-50 casillas; cada zona enseña algo nuevo.

const NOMBRE: String = "Nivel 3 · Las raíces profundas"
const SUBTITULO: String = "Acto 2"
const OBJETIVO: String = "Usa el disparo de luz y baja por las raíces hasta la grieta."


static func construir(n: Nivel) -> void:
	n.tamano(200, 24)
	n.zona(0, 50, "Zona 1 · Raíces del Árbol Madre", 0.85, true)
	n.zona(50, 105, "Zona 2 · Galería de raíces", 0.85, true)
	n.zona(105, 150, "Zona 3 · El pozo de luciérnagas", 0.85, true)
	n.zona(150, 200, "Zona 4 · La puerta de la Bruma", 0.88, true)
	n.inicio(2, 12)

	# --- Zona 1: Raíces del Árbol Madre (enseña el disparo) ---
	n.bloque(0, 49, 0, 1)                      # techo
	n.suelo(0, 33, 13)
	n.farol(4, 12)
	n.nota_raiz(6, 12, "La voz del Árbol: \"Pequeña, tu linterna ahora dispara. Haz clic derecho y la chispa irá hacia donde apuntes con el mouse.\"")
	n.cartel(10, 12, "Cada chispa gasta 6 de luz. Las sombras aguantan dos chispas y, al deshacerse, sueltan una luciérnaga que recarga tu luz.")
	n.sombra("patrulla", 16, 12, 13, 20)
	n.frasco(21, 12)
	n.cartel(22, 12, "Ese brasero de allá arriba está muy alto: ni la linterna lo alcanza. Desde aquí, dispárale tres chispas en diagonal para encenderlo y abrir las raíces.")
	n.sombra("patrulla", 26, 12, 23, 29)
	n.bloque(30, 32, 4, 5)                     # saliente alto (inalcanzable)
	n.brasero(30, 3, "a")                      # en la orilla izquierda: se le dispara en diagonal
	n.agua(34, 39, 14)
	n.bloque(34, 39, 15, 23)
	n.plataforma_luz(36, 37, 11)
	n.suelo(40, 49, 13)
	n.puerta(44, 8, 12, "a")

	# --- Zona 2: Galería de raíces (primeras lanzadoras, coberturas) ---
	n.bloque(50, 104, 0, 5)                    # techo bajo
	n.suelo(50, 104, 13)
	n.farol(52, 12)
	n.cartel(54, 12, "Lanzadora de bruma: dispara esquirlas cuando te ve. Escóndete detrás de las raíces y dispárale cuando se asome. Tu linterna la asusta y no la deja disparar.")
	n.bloque(60, 60, 10, 12)                   # cobertura
	n.lanzadora(68, 9)
	n.frasco(71, 12)
	n.bloque(76, 76, 10, 12)                   # cobertura
	n.sombra("patrulla", 80, 12, 77, 87)
	n.lanzadora(84, 8)
	n.frasco(88, 12)
	n.bloque(92, 93, 10, 12)                   # cobertura
	n.sombra("cazadora", 97, 12, 94, 102)
	n.lanzadora(99, 9)
	n.frasco(101, 12)
	n.farol(103, 12)

	# --- Zona 3: El pozo de luciérnagas (primer descenso, 8 casillas) ---
	n.bloque(105, 149, 0, 3)                   # techo
	n.suelo(105, 108, 13)
	n.cartel(106, 12, "El pozo de luciérnagas. Baja por las plataformas escondidas: ilumínalas con la linterna mientras saltas. Abajo hay espinas.")
	n.plataforma_luz(110, 111, 15)
	n.bloque(114, 116, 17, 17)                 # saliente sólido
	n.frasco(115, 16)
	n.plataforma_luz(119, 120, 19)
	n.suelo(109, 122, 22)
	n.espinas(109, 122, 21)
	n.suelo(123, 199, 21)
	n.farol(125, 20)
	n.frasco(130, 20)
	n.sombra("cazadora", 137, 20, 127, 146)

	# --- Zona 4: La puerta de la Bruma (arena con 1 oleada) ---
	n.bloque(150, 199, 0, 12)                  # techo de la arena
	n.farol(153, 20)
	n.cartel(155, 20, "La puerta de la Bruma. Al entrar, las raíces se cerrarán detrás de ti. Vence a todas las sombras para abrir el paso.")
	n.frasco(157, 20)
	n.puerta_arena(160, 13, 20, "puerta")                # entrada: se cierra al entrar
	n.bloque(169, 170, 18, 20)                 # coberturas dentro de la arena
	n.bloque(176, 176, 18, 20)
	n.arena(160, 185, "puerta", [
		[["sombra", "patrulla", 165, 20], ["sombra", "cazadora", 173, 20],
		 ["sombra", "patrulla", 181, 20], ["lanzadora", 179, 16]],
	])
	n.puerta_arena(186, 13, 20, "puerta", true)          # salida: abre al vencer
	n.nota_raiz(190, 20, "La voz del Árbol: \"Más abajo se abre la grieta. Sigue bajando, pequeña. Tu papá te necesita.\"")
	n.frasco(192, 20)
	n.salida(196, 20)
