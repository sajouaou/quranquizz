extends RefCounted
## Qualité graphique (Réglages) : trois niveaux pour que le jeu reste fluide sur les petits appareils.
##   HIGH   : tout (avant-plan flou, rayons, lueurs, murs en volume qui tournent, sol en perspective, vignette)
##   MEDIUM : sans lueurs floues ni rayons, moins d'étoiles et de poussières
##   LOW    : en plus, sans avant-plan, sans murs en volume, sans joints de sol, sans vignette ; fond redessiné moins souvent
## Les scripts lisent `Gfx.level` au moment de dessiner : un changement s'applique tout de suite, sans recharger le monde.

enum { LOW, MEDIUM, HIGH }

static var level: int = HIGH


## Applique le réglage enregistré : -1 = automatique (moyenne sur téléphone et navigateur, haute sur ordinateur).
static func apply(saved: int) -> void:
	if saved < LOW or saved > HIGH:
		level = MEDIUM if (OS.has_feature("mobile") or OS.has_feature("web")) else HIGH
	else:
		level = saved


static func low() -> bool:
	return level == LOW


static func high() -> bool:
	return level == HIGH


## Choisit une valeur selon le niveau : pick(basse, moyenne, haute).
static func pick(low_v: Variant, medium_v: Variant, high_v: Variant) -> Variant:
	return [low_v, medium_v, high_v][level]
