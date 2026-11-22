extends RefCounted
## Nivel de PRUEBA del acto 2 (no es parte del juego).
## Se abre con escenas/niveles/nivel_prueba_acto2.tscn y F6.
## Prueba: disparo de luz, sombras con vida, embestida de la cazadora,
## lanzadora de bruma, brasero lejano encendido con chispas, luciérnagas pequeñas
## y el campo de luz (Q) con cristales.

const NOMBRE: String = "Prueba del acto 2"
const SUBTITULO: String = "Solo para probar"
const OBJETIVO: String = "Prueba el disparo de luz contra los enemigos."


static func construir(n: Nivel) -> void:
	n.tamano(100, 18)
	n.zona(0, 100, "Prueba del acto 2", 0.80, false)
	n.inicio(2, 13)
	n.suelo(0, 69, 14)
	n.farol(4, 13)
	n.cartel(7, 13, "Clic derecho: disparo de luz hacia el mouse (gasta 6 de luz). Las sombras aguantan 2 chispas y sueltan una luciérnaga (+5).")
	n.sombra("patrulla", 14, 13, 11, 18)
	n.frasco(19, 13)
	n.cartel(21, 13, "La cazadora: si te acercas a menos de 4 casillas, se detiene, le brillan los ojos y embiste. ¡Ilumínala o dispárale!")
	n.sombra("cazadora", 28, 13, 23, 33)
	n.cartel(35, 13, "La lanzadora dispara esquirlas cuando te ve. Escóndete detrás del bloque. Aguanta 3 chispas.")
	n.bloque(39, 40, 12, 13)
	n.lanzadora(46, 10)
	n.frasco(42, 13)
	n.farol(49, 13)
	n.cartel(51, 13, "Ese brasero está lejos, al otro lado del agua. Dispárale 3 chispas para encenderlo y abrir las raíces.")
	n.agua(53, 58, 15)
	n.bloque(53, 58, 16, 17)
	n.plataforma_luz(55, 56, 12)
	n.brasero(58, 13, "a")
	n.suelo(59, 71, 14)
	n.puerta(62, 8, 13, "a")
	n.flor(65, 13)
	n.farol(68, 13)
	n.cartel(70, 13, "Q (o clic izquierdo + derecho a la vez): CAMPO DE LUZ. Ilumina todo a tu alrededor 4 s, daña a los enemigos cercanos y hace aparecer los cristales.")
	n.agua(72, 82, 15)
	n.bloque(72, 82, 16, 17)
	n.cristal(74, 75, 12)
	n.cristal(78, 79, 11)
	n.suelo(83, 99, 14)
	n.sombra("patrulla", 88, 13, 85, 92)
	n.lanzadora(91, 9)
	n.salida(97, 13)
