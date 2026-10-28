class_name AmmoBuilding
extends Building
## A defence structure that consumes a delivered item as ammunition.

@export var ammo_item := "ore"
@export var ammo_per_item := 5
@export var max_ammo := 30
@export var fire_interval := 0.35
@export var max_targets := 1

var ammo := 10
var cooldown := 0.0

@onready var range_area: Area2D = $RangeArea
@onready var ammo_bar: StatBar = $AmmoBar


func _ready() -> void:
	ammo_bar.set_fraction(float(ammo) / max_ammo)


func accepts(item: String) -> bool:
	return item == ammo_item and ammo + ammo_per_item <= max_ammo


func receive(_item: String) -> void:
	ammo += ammo_per_item
	ammo_bar.set_fraction(float(ammo) / max_ammo)


func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown > 0.0 or ammo <= 0:
		return
	var targets := _targets()
	if targets.is_empty():
		return
	_fire(targets)
	ammo -= 1
	cooldown = fire_interval
	ammo_bar.set_fraction(float(ammo) / max_ammo)


func _targets() -> Array:
	var list := range_area.get_overlapping_areas().filter(func(a): return a is Enemy and not a.dead)
	list.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	return list.slice(0, max_targets)


func _fire(_targets_in_range: Array) -> void:
	pass
