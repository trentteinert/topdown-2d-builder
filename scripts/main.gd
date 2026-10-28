class_name Main
extends Node2D
## Game orchestrator: inventory, building registry, feedback effects and the win / lose flow.
## Everything visible lives in child scenes; this script only wires them together.

const WIN_NIGHTS := 8
const BUILDING_SCENES := {
	Defs.Build.DRILL: preload("res://scenes/buildings/drill.tscn"),
	Defs.Build.CONVEYOR: preload("res://scenes/buildings/conveyor.tscn"),
	Defs.Build.TURRET: preload("res://scenes/buildings/turret.tscn"),
	Defs.Build.TESLA: preload("res://scenes/buildings/tesla.tscn"),
}
const POPUP_SCENE := preload("res://scenes/effects/popup.tscn")
const POOF_SCENE := preload("res://scenes/effects/poof.tscn")

var inventory := Inventory.new(12)
var kills := 0
var buildings := {}  # Vector2i -> Building
var finished := false

var _pickups := {}  # item id -> amount waiting to be shown as one popup
var _pickup_pos := Vector2.ZERO
var _pickup_timer := 0.0
var _full_cooldown := 0.0

@onready var world: World = $World
@onready var core: Core = $Entities/Core
@onready var buildings_root: Node2D = $Entities/Buildings
@onready var enemies_root: Node2D = $Entities/Enemies
@onready var player: Player = $Entities/Player
@onready var projectiles: Node2D = $Projectiles
@onready var effects: Node2D = $Effects
@onready var builder: Builder = $Builder
@onready var day_night: DayNight = $DayNight
@onready var spawner: Spawner = $Spawner
@onready var hud: Hud = $HUD


func _ready() -> void:
	randomize()
	player.game = self
	builder.game = self
	spawner.game = self
	world.deposits_root = $Entities/Deposits
	world.props_root = $Entities/Props
	world.generate()
	core.position = Defs.cell_center(Defs.CORE_CELL)
	player.respawn()
	inventory.add("ore", 40)
	core.destroyed.connect(_finish.bind(false))
	core.damaged.connect(func(_amount): player.shake(3.0, 0.15))
	day_night.night_started.connect(_on_night_started)
	day_night.dawn.connect(_on_dawn)
	hud.bind(self)


func _process(delta: float) -> void:
	_full_cooldown -= delta
	if not _pickups.is_empty():
		_pickup_timer -= delta
		if _pickup_timer <= 0.0:
			_flush_pickups()


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


func on_enemy_died(enemy: Enemy) -> void:
	kills += 1
	spawn_poof(enemy.position + Vector2(0, -6), Color(0.85, 0.25, 0.3), 12)
	if inventory.add("scrap") == 0:
		notify_pickup("scrap", 1, enemy.position)
	if randf() < 0.3 and inventory.add("ore") == 0:
		notify_pickup("ore", 1, enemy.position)


# ---------------------------------------------------------------- items & feedback

func add_item(item: String, amount := 1) -> bool:
	return inventory.add(item, amount) == 0


## Hands an item to whatever sits at `cell`. Returns true if it was accepted.
func deliver(cell: Vector2i, item: String) -> bool:
	if Defs.is_core(cell):
		return add_item(item)
	var b := building_at(cell)
	if b and b.accepts(item):
		b.receive(item)
		return true
	return false


## Collects pickups for half a second so mining shows one "+5 Ore" instead of five popups.
func notify_pickup(id: String, amount: int, at: Vector2) -> void:
	if _pickups.is_empty():
		_pickup_timer = 0.5
	_pickups[id] = _pickups.get(id, 0) + amount
	_pickup_pos = at


func _flush_pickups() -> void:
	var i := 0
	for id in _pickups:
		spawn_popup(_pickup_pos + Vector2(0, -24 - i * 16), "+%d %s" % [_pickups[id], Items.display_name(id)], Items.icon(id), Items.color(id))
		i += 1
	_pickups.clear()


func notify_full(at: Vector2) -> void:
	if _full_cooldown <= 0.0:
		_full_cooldown = 1.5
		spawn_popup(at + Vector2(0, -34), "Inventory full!", null, Color(1, 0.45, 0.4))


func spawn_popup(at: Vector2, text: String, texture: Texture2D = null, tint := Color.WHITE) -> void:
	var p: FloatingText = POPUP_SCENE.instantiate()
	effects.add_child(p)
	p.show_at(at, text, texture, tint)


func spawn_poof(at: Vector2, tint: Color, count := 10) -> void:
	var p: Poof = POOF_SCENE.instantiate()
	effects.add_child(p)
	p.burst(at, tint, count)


# ---------------------------------------------------------------- buildings

func building_at(cell: Vector2i) -> Building:
	return buildings.get(cell)


## How many of `type` the inventory could pay for right now.
func max_buildable(type: int) -> int:
	var n := 999
	for id in Defs.COST[type]:
		n = mini(n, inventory.count(id) / Defs.COST[type][id])
	return n


func can_place(cell: Vector2i, type: int) -> bool:
	if not Defs.in_bounds(cell) or Defs.is_core(cell) or buildings.has(cell) or world.prop_at(cell):
		return false
	if type == Defs.Build.DRILL and world.resource_at(cell) == null:
		return false
	return inventory.has(Defs.COST[type])


func try_place(cell: Vector2i, type: int, facing: int) -> bool:
	if not can_place(cell, type):
		return false
	inventory.pay(Defs.COST[type])
	var b: Building = BUILDING_SCENES[type].instantiate()
	b.game = self
	b.type = type
	buildings_root.add_child(b)
	b.setup(cell, facing)
	b.destroyed.connect(_on_building_destroyed)
	buildings[cell] = b
	spawn_poof(Defs.cell_center(cell) + Vector2(0, 12), Color(0.8, 0.75, 0.6), 6)
	return true


func remove_building(cell: Vector2i) -> void:
	var b := building_at(cell)
	if b == null:
		return
	for id in Defs.COST[b.type]:
		inventory.add(id, Defs.COST[b.type][id] / 2)
	_on_building_destroyed(cell)


func _on_building_destroyed(cell: Vector2i) -> void:
	var b := building_at(cell)
	buildings.erase(cell)
	if b:
		spawn_poof(b.position + Vector2(0, 4), Color(0.5, 0.52, 0.6), 10)
		b.queue_free()
