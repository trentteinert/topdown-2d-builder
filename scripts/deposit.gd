class_name ResourceDeposit
extends Node2D
## A minable resource node. Shrinks as it is mined and shakes on every hit.

signal depleted

@export var item := "ore"
@export var amount := 300

var full := 1

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	full = maxi(amount, 1)


## Removes one unit and returns the item type.
func take() -> String:
	amount -= 1
	if amount <= 0:
		depleted.emit()
		queue_free()
		return item
	var s := lerpf(0.6, 1.0, float(amount) / full)
	sprite.scale = Vector2(s, s)
	sprite.position = Vector2(0, 16.0 * (1.0 - s))  # keep the base on the tile edge
	var tween := create_tween()
	tween.tween_property(sprite, "position:x", 2.0, 0.03)
	tween.tween_property(sprite, "position:x", -2.0, 0.05)
	tween.tween_property(sprite, "position:x", 0.0, 0.03)
	return item
