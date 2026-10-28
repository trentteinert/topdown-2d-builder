class_name Items
## Static item database. Add a new resource here and it shows up in the inventory and HUD.

const IDS := ["ore", "crystal", "scrap"]
const DATA := {
	"ore": {"name": "Ore", "icon": preload("res://assets/sprites/ico_ore.png"), "stack": 50, "color": Color(0.92, 0.6, 0.3)},
	"crystal": {"name": "Crystal", "icon": preload("res://assets/sprites/ico_crystal.png"), "stack": 50, "color": Color(0.45, 0.95, 1.0)},
	"scrap": {"name": "Scrap", "icon": preload("res://assets/sprites/ico_scrap.png"), "stack": 50, "color": Color(0.7, 0.74, 0.82)},
}


static func display_name(id: String) -> String:
	return DATA[id].name


static func icon(id: String) -> Texture2D:
	return DATA[id].icon


static func stack_size(id: String) -> int:
	return DATA[id].stack


static func color(id: String) -> Color:
	return DATA[id].color
