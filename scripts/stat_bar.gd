class_name StatBar
extends Node2D
## Small health / ammo bar made of two ColorRects.

@export var width := 24.0
@export var height := 5.0
@export var fill_color := Color(0.3, 0.9, 0.5)

@onready var back: ColorRect = $Back
@onready var fill: ColorRect = $Fill


func _ready() -> void:
	back.size = Vector2(width, height)
	fill.color = fill_color
	fill.size = Vector2(width, height)


func set_fraction(f: float) -> void:
	fill.size.x = width * clampf(f, 0.0, 1.0)
