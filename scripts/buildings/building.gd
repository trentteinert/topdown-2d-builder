class_name Building
extends Node2D
## Base class for everything placed on the grid.

signal destroyed(cell: Vector2i)

@export var max_hp := 40.0
## Rotate the "Pivot" child to match the placement direction (off for turrets, which aim).
@export var rotate_pivot := true

var game: Main
var type := Defs.Build.NONE
var cell := Vector2i.ZERO
var facing := 0
var hp := 0.0

@onready var health_bar: StatBar = $HealthBar
@onready var pivot: Node2D = get_node_or_null("Pivot")


func setup(c: Vector2i, f: int) -> void:
	cell = c
	facing = f
	hp = max_hp
	position = Defs.cell_center(c)
	if rotate_pivot and pivot:
		pivot.rotation = f * PI / 2.0


func accepts(_item: String) -> bool:
	return false


func receive(_item: String) -> void:
	pass


func take_damage(amount: float) -> void:
	hp -= amount
	health_bar.show()
	health_bar.set_fraction(hp / max_hp)
	if hp <= 0.0:
		destroyed.emit(cell)
