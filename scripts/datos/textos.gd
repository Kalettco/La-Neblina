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

const FINAL: Array[String] = [
	"Lía entregó toda su luz. La linterna se apagó y todo quedó negro. Por primera vez, no salió corriendo.",
	"El Árbol Madre se encendió desde las raíces hasta la copa. La Bruma se deshizo como humo en el viento.",
	"Entre las raíces, Andrés abrió los ojos. Las luciérnagas volvieron a llenar el bosque.",
	"Esa noche, en San Isidro de las Nubes, Lía apagó la luz para dormir.",
]

## Opciones de la historia FINAL: linterna apagada en la página 1 y última página en dorado.
const OPCIONES_FINAL: Dictionary = {
	"linterna_apagada": [0],
	"dorada": [3],
}

const TITULO: String = "Neblina"
const LEMA: String = "La luz se gasta. El miedo también."
