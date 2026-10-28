class_name World
extends Node2D
## The ground. Generates deposits and decorative props into the Y-sorted entity layers.

@export var ore_scene: PackedScene
@export var crystal_scene: PackedScene
@export var tree_scene: PackedScene
@export var rock_scene: PackedScene

var deposits := {}  # Vector2i -> ResourceDeposit
var props := {}  # Vector2i -> Node2D (blocks building)
var deposits_root: Node2D
var props_root: Node2D


func generate() -> void:
	var ore_noise := FastNoiseLite.new()
	ore_noise.seed = randi()
	ore_noise.frequency = 0.09
	var crystal_noise := FastNoiseLite.new()
	crystal_noise.seed = randi()
	crystal_noise.frequency = 0.1
	var has_near_ore := false
	for x in Defs.W:
		for y in Defs.H:
			var c := Vector2i(x, y)
			var d := c.distance_to(Defs.CORE_CELL)
			if d < 5.0:
				continue
			if ore_noise.get_noise_2d(x, y) > 0.28:
				spawn_deposit(c, "ore", 300)
				has_near_ore = has_near_ore or d < 16.0
			elif d > 14.0 and crystal_noise.get_noise_2d(x, y) > 0.34:
				spawn_deposit(c, "crystal", 150)
	if not has_near_ore:
		for x in range(-1, 2):
			for y in range(-1, 2):
				spawn_deposit(Defs.CORE_CELL + Vector2i(9 + x, y), "ore", 300)
	_generate_props()


func _generate_props() -> void:
	for x in Defs.W:
		for y in Defs.H:
			var c := Vector2i(x, y)
			if deposits.has(c) or c.distance_to(Defs.CORE_CELL) < 6.0:
				continue
			var r := randf()
			if r < 0.018:
				_spawn_prop(c, tree_scene)
			elif r < 0.03:
				_spawn_prop(c, rock_scene)


func _spawn_prop(cell: Vector2i, scene: PackedScene) -> void:
	var p: Node2D = scene.instantiate()
	p.position = Defs.cell_center(cell)
	props_root.add_child(p)
	props[cell] = p


func spawn_deposit(cell: Vector2i, item: String, amount: int) -> void:
	if deposits.has(cell):
		return
	var d: ResourceDeposit = (ore_scene if item == "ore" else crystal_scene).instantiate()
	d.amount = amount
	d.position = Defs.cell_center(cell)
	d.depleted.connect(_on_depleted.bind(cell))
	deposits_root.add_child(d)
	deposits[cell] = d


func _on_depleted(cell: Vector2i) -> void:
	deposits.erase(cell)


func prop_at(cell: Vector2i) -> bool:
	return props.has(cell)


func resource_at(cell: Vector2i) -> ResourceDeposit:
	return deposits.get(cell)


func nearest_resource(p: Vector2, radius: float) -> ResourceDeposit:
	var pc := Defs.world_to_cell(p)
	var reach := ceili(radius / Defs.TILE)
	var best: ResourceDeposit = null
	var best_d := radius
	for x in range(pc.x - reach, pc.x + reach + 1):
		for y in range(pc.y - reach, pc.y + reach + 1):
			var d: ResourceDeposit = deposits.get(Vector2i(x, y))
			if d and d.position.distance_to(p) < best_d:
				best_d = d.position.distance_to(p)
				best = d
	return best
