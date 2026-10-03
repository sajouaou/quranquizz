extends RefCounted
## Second rêve : la maison (la même, un autre soir), une ville de fête, l'avenue d'un homme riche, la rue de l'ivresse, puis le chemin qui longe un cimetière (vu de loin).
## Les constantes du monde du chapitre 2 et la liste de ses zones.

const ZoneHouse := preload("res://scripts/world/zones/zone_house.gd")
const ZoneLove := preload("res://scripts/world/zones/zone_love.gd")
const ZoneParade := preload("res://scripts/world/zones/zone_parade.gd")
const ZoneSpirits := preload("res://scripts/world/zones/zone_spirits.gd")
const ZoneGraves := preload("res://scripts/world/zones/zone_graves.gd")

const WORLD_W := 17800.0
const ZONES := [
	["home", 0.0, 1935.0],
	["love", 1935.0, 6400.0],
	["parade", 6400.0, 9600.0],
	["spirits", 9600.0, 12400.0],
	["graves", 12400.0, 17800.0],
]
# [x, haut, bas, bord, densité (inutilisée)]
const GROUND_STOPS := [
	[1935.0, Color("8a4a6e"), Color("2a1734"), Color("f0a0b8"), 0.0],
	[6200.0, Color("8a4a6e"), Color("2a1734"), Color("f0a0b8"), 0.0],
	[6800.0, Color("b98a4a"), Color("3a2410"), Color("ffe08a"), 0.0],
	[9400.0, Color("b98a4a"), Color("3a2410"), Color("ffe08a"), 0.0],
	[10000.0, Color("3a1f4e"), Color("12081f"), Color("b04a8a"), 0.0],
	[12200.0, Color("3a1f4e"), Color("12081f"), Color("b04a8a"), 0.0],
	[12800.0, Color("1c2440"), Color("080b18"), Color("5a6aa0"), 0.0],
	[17000.0, Color("1c2440"), Color("080b18"), Color("5a6aa0"), 0.0],
	[17800.0, Color("3a3560"), Color("141230"), Color("f0c88a"), 0.0],
]


static func make_zones() -> Array:
	return [ZoneHouse.new(), ZoneLove.new(), ZoneParade.new(), ZoneSpirits.new(), ZoneGraves.new()]
