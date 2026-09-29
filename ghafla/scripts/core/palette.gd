extends RefCounted
## Couleurs du jeu, et ciel interpolé selon la position dans le monde.

const PARCHMENT := Color("f5eedc")
const PARCHMENT_SHADE := Color("e4d9bd")
const GOLD := Color("e9c46a")
const GOLD_DEEP := Color("b8862b")
const INK := Color("0a0920")
const NIGHT := Color("070a1f")
const EMERALD := Color("1f6f5c")
const THOBE := Color("efe9dc")
const THOBE_SHADE := Color("c9c0ad")
const SKIN := Color("c48a5e")

# Ciel du rêve. Chaque étape : [x, haut, milieu, horizon, étoiles (0-1), lueur de l'aube (0-1)].
# Le temps ne s'écoule plus comme avant : chaque zone fige un moment différent de la journée.
const SKY_STOPS := [
	[0.0, Color("3b2c72"), Color("8d5c9c"), Color("f6b48a"), 0.16, 0.70],
	[1900.0, Color("3b2c72"), Color("8d5c9c"), Color("f6b48a"), 0.16, 0.70],
	[2500.0, Color("231b55"), Color("7d519c"), Color("f8b98c"), 0.55, 0.90],
	[4300.0, Color("231b55"), Color("7d519c"), Color("f8b98c"), 0.55, 0.90],
	[5100.0, Color("3b2568"), Color("c4627b"), Color("f8cb6e"), 0.12, 1.00],
	[8300.0, Color("3b2568"), Color("c4627b"), Color("f8cb6e"), 0.12, 1.00],
	[9000.0, Color("0d1030"), Color("1b1c4c"), Color("33305f"), 0.60, 0.00],
	[12200.0, Color("0d1030"), Color("1b1c4c"), Color("33305f"), 0.60, 0.00],
	[12900.0, Color("050716"), Color("0f1842"), Color("2b2a68"), 1.00, 0.10],
	[14700.0, Color("050716"), Color("101a48"), Color("3a2f78"), 1.00, 0.30],
	[15400.0, Color("1a1748"), Color("6a4a8e"), Color("f5c07f"), 0.30, 1.00],
]


static func sky_at(x: float) -> Dictionary:
	var stops: Array = SKY_STOPS
	if x <= stops[0][0]:
		return _stop(stops[0])
	for i in range(stops.size() - 1):
		var a: Array = stops[i]
		var b: Array = stops[i + 1]
		if x <= b[0]:
			var t: float = smoothstep(a[0], b[0], x)
			return {
				"top": (a[1] as Color).lerp(b[1], t),
				"mid": (a[2] as Color).lerp(b[2], t),
				"bottom": (a[3] as Color).lerp(b[3], t),
				"stars": lerpf(a[4], b[4], t),
				"glow": lerpf(a[5], b[5], t),
			}
	return _stop(stops[stops.size() - 1])


static func _stop(s: Array) -> Dictionary:
	return {"top": s[1], "mid": s[2], "bottom": s[3], "stars": s[4], "glow": s[5]}
