class_name ResourceDeposit
extends Node2D
## A minable resource node on the ground.

signal depleted

@export var item := "ore"
@export var amount := 300


## Removes one unit and returns the item type.
func take() -> String:
	amount -= 1
	if amount <= 0:
		depleted.emit()
		queue_free()
	return item
