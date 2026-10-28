class_name Main
extends Node2D
## Game orchestrator: inventory, building registry and the win / lose flow.
## Everything visible lives in child scenes; this script only wires them together.

const WIN_NIGHTS := 8
const BUILDING_SCENES := {
	Defs.Build.DRILL: preload("res://scenes/buildings/drill.tscn"),
	Defs.Build.CONVEYOR: preload("res://scenes/buildings/conveyor.tscn"),
	Defs.Build.TURRET: preload("res://scenes/buildings/turret.tscn"),
	Defs.Build.TESLA: preload("res://scenes/buildings/tesla.tscn"),
}

var inv := {"ore": 30, "crystal": 0}
var kills := 0
var buildings := {}  # Vector2i -> Building
var finished := false

@onready var world: World = $World
@onready var core: Core = $Core
@onready var buildings_root: Node2D = $Buildings
@onready var enemies_root: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var player: Player = $Player
@onready var builder: Builder = $Builder
@onready var day_night: DayNight = $DayNight
@onready var spawner: Spawner = $Spawner
@onready var hud: Hud = $HUD


func _ready() -> void:
	randomize()
	player.game = self
	builder.game = self
	spawner.game = self
	world.generate()
	core.position = Defs.cell_center(Defs.CORE_CELL)
	player.respawn()
	core.destroyed.connect(_finish.bind(false))
	day_night.night_started.connect(_on_night_started)
	day_night.dawn.connect(_on_dawn)


func _process(_delta: float) -> void:
	var phase := ""
	if day_night.is_night:
		phase = "NIGHT %d/%d  -  %ds until dawn" % [day_night.night, WIN_NIGHTS, day_night.cycle_length() - day_night.time_in_cycle()]
	else:
		phase = "Day %d  -  night falls in %ds" % [day_night.night + 1, day_night.day_length - day_night.time_in_cycle()]
	var sel := "none (shooting)"
	if builder.selected != Defs.Build.NONE:
		sel = "%s, facing %s" % [Defs.NAMES[builder.selected], Defs.DIR_NAMES[builder.facing]]
	hud.update_status(phase, inv, kills, core.hp, core.max_hp, player.hp, sel)


# ---------------------------------------------------------------- flow

func _on_night_started(night: int) -> void:
	spawner.begin_night(night, day_night.night_length)


func _on_dawn(night: int) -> void:
	spawner.end_night()
	core.heal(100.0)
	if night >= WIN_NIGHTS:
		_finish(true)


func _finish(won: bool) -> void:
	if finished:
		return
	finished = true
	hud.show_message(("YOU SURVIVED %d NIGHTS" % WIN_NIGHTS if won else "THE CORE HAS FALLEN") + "\nEnter to restart")
	get_tree().paused = true


func on_enemy_died(_enemy: Enemy) -> void:
	kills += 1
	add_item("ore")


# ---------------------------------------------------------------- items

func add_item(item: String, amount := 1) -> void:
	inv[item] += amount


## Hands an item to whatever sits at `cell`. Returns true if it was accepted.
func deliver(cell: Vector2i, item: String) -> bool:
	if Defs.is_core(cell):
		add_item(item)
		return true
	var b := building_at(cell)
	if b and b.accepts(item):
		b.receive(item)
		return true
	return false


# ---------------------------------------------------------------- buildings

func building_at(cell: Vector2i) -> Building:
	return buildings.get(cell)


func can_afford(type: int) -> bool:
	for k in Defs.COST[type]:
		if inv[k] < Defs.COST[type][k]:
			return false
	return true


func can_place(cell: Vector2i, type: int) -> bool:
	if not Defs.in_bounds(cell) or Defs.is_core(cell) or buildings.has(cell):
		return false
	if type == Defs.Build.DRILL and world.resource_at(cell) == null:
		return false
	return can_afford(type)


func try_place(cell: Vector2i, type: int, facing: int) -> bool:
	if not can_place(cell, type):
		return false
	for k in Defs.COST[type]:
		inv[k] -= Defs.COST[type][k]
	var b: Building = BUILDING_SCENES[type].instantiate()
	b.game = self
	b.type = type
	buildings_root.add_child(b)
	b.setup(cell, facing)
	b.destroyed.connect(_on_building_destroyed)
	buildings[cell] = b
	return true


func remove_building(cell: Vector2i) -> void:
	var b := building_at(cell)
	if b == null:
		return
	for k in Defs.COST[b.type]:
		inv[k] += Defs.COST[b.type][k] / 2
	_on_building_destroyed(cell)


func _on_building_destroyed(cell: Vector2i) -> void:
	var b := building_at(cell)
	buildings.erase(cell)
	if b:
		b.queue_free()
