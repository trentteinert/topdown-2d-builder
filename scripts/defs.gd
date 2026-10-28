class_name Defs
## Shared constants and grid helpers.

const TILE := 32
const W := 90
const H := 60
const CORE_CELL := Vector2i(45, 30)
const DIRS := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const DIR_NAMES := ["East", "South", "West", "North"]
const DIR_KEYS := ["e", "s", "w", "n"]

enum Build { NONE, DRILL, CONVEYOR, TURRET, TESLA }

const COST := {
	Build.DRILL: {"ore": 10},
	Build.CONVEYOR: {"ore": 1},
	Build.TURRET: {"ore": 15},
	Build.TESLA: {"ore": 10, "crystal": 8, "scrap": 5},
}
const NAMES := {
	Build.DRILL: "Drill",
	Build.CONVEYOR: "Conveyor",
	Build.TURRET: "Gun turret",
	Build.TESLA: "Tesla coil",
}
const BUILD_ICONS := {
	Build.DRILL: preload("res://assets/sprites/ico_drill.png"),
	Build.CONVEYOR: preload("res://assets/sprites/ico_conveyor.png"),
	Build.TURRET: preload("res://assets/sprites/ico_turret.png"),
	Build.TESLA: preload("res://assets/sprites/ico_tesla.png"),
}


static func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


static func cell_center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * TILE


static func is_core(c: Vector2i) -> bool:
	return absi(c.x - CORE_CELL.x) <= 1 and absi(c.y - CORE_CELL.y) <= 1


static func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H
