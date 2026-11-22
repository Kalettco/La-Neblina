class_name Textos
extends RefCounted
## Textos de la historia (Story Circle de Dan Harmon).

const INTRO: Array[String] = [
	"San Isidro de las Nubes. Lía tiene doce años, trepa árboles mejor que nadie y todavía duerme con la luz encendida.",
	"Su abuela le contaba que las luciérnagas guardan la luz que mantiene vivo al bosque nuboso. Lía siempre pensó que era un cuento para dormir.",
	"Una noche bajó del cerro una neblina negra. La gente del pueblo la llamó la Bruma. Las luciérnagas desaparecieron.",
	"Andrés, su papá guardaparques, entró al bosque a revisar los senderos. No regresó.",
	"Lía descolgó la vieja linterna de la abuela. Estaba apagada, hasta que una luciérnaga perdida se metió dentro. Entonces brilló.",
]

const PUENTE: Array[String] = [
	"Al final del sendero, Lía encontró una nota clavada en un poste, con la letra de su papá.",
	"\"La Bruma sale del Árbol Madre. Se está secando porque perdió su luz. Las tres luciérnagas guardianas pueden ayudarlo.\"",
	"Lía apretó la linterna y siguió hacia el corazón del bosque.",
]

# --- ACTO 2: "El alma de Andrés" ---

## Después de sanar el Árbol Madre (fin del nivel 2).
const ARBOL_HABLA: Array[String] = [
	"El Árbol Madre brilló de nuevo. Andrés estaba libre, pero sus ojos seguían vacíos, como una linterna sin luciérnagas.",
	"—Pequeña —dijo una voz desde las raíces—. Tu padre volvió, pero la Bruma se quedó con su alma.",
	"—Se la llevó al fondo de la tierra, al Corazón de la Bruma. Allá abajo la luz no solo ilumina: también lucha.",
	"Las raíces encendieron una chispa nueva dentro de la linterna. Ahora su luz podía disparar.",
	"Lía dejó a su papá al cuidado del árbol, apretó la linterna y bajó por las raíces.",
]
## Lía entregó toda su luz: la linterna sigue apagada hasta que las raíces la encienden.
const OPCIONES_ARBOL_HABLA: Dictionary = {
	"linterna_apagada": [0, 1, 2],
}

## Entre el nivel 4 y el 5.
const REINA: Array[String] = [
	"En el fondo de la grieta, donde ni la Bruma se atrevía a entrar, dormía una luciérnaga enorme.",
	"—Llevas la linterna de tu abuela —susurró la Luciérnaga Reina—. Ella también bajó hasta aquí, hace muchos años.",
	"—Toma mi luz. Cuando la oscuridad sea total, haz que todo brille a la vez.",
]

## Entre el nivel 5 y el 6.
const ANTES_CORAZON: Array[String] = [
	"Las cavernas terminaban en una puerta de raíces negras que latía como un corazón.",
	"Del otro lado se escuchaba la voz de su papá, muy lejos, llamándola.",
	"Lía respiró hondo. Ya no le temía a la oscuridad. Ahora la oscuridad le temía a ella.",
]

## Después de vencer al jefe (fin del juego).
const FINAL: Array[String] = [
	"El Devorador de Luz se deshizo en mil chispas. Entre ellas flotaba una luz dorada y tibia: el alma de Andrés.",
	"Lía la guardó en la linterna y subió de regreso, siguiendo a las luciérnagas que volvían al bosque.",
	"Bajo el Árbol Madre, Andrés abrió los ojos y la abrazó. Esta vez la reconoció.",
	"Las luciérnagas volvieron a llenar el bosque nuboso. La Bruma no regresó nunca más.",
	"Esa noche, en San Isidro de las Nubes, Lía apagó la luz para dormir.",
]
## Última página en dorado.
const OPCIONES_FINAL: Dictionary = {
	"dorada": [4],
}

# --- Pantallas de habilidad nueva ---

const HABILIDAD_DISPARO_TITULO: String = "NUEVA HABILIDAD: Disparo de luz"
const HABILIDAD_DISPARO_TEXTO: String = "Haz clic derecho para lanzar una chispa de luz hacia el mouse. Cada disparo gasta un poco de luz."
const HABILIDAD_CAMPO_TITULO: String = "NUEVA HABILIDAD: Campo de luz"
const HABILIDAD_CAMPO_TEXTO: String = "Presiona Q (o clic izquierdo y derecho a la vez) para iluminar todo a tu alrededor durante unos segundos. Después necesita recargarse."

const TITULO: String = "Neblina"
const LEMA: String = "La luz se gasta. El miedo también."
