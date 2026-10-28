class_name Conveyor
extends Building
## Carries one item at a time to the next cell in its facing direction.

const MOVE_TIME := 0.3

var item := ""
var progress := 0.0

@onready var dot: Sprite2D = $ItemDot


func accepts(_item: String) -> bool:
	return item == ""


func receive(new_item: String) -> void:
	item = new_item
	progress = 0.0
	dot.texture = Items.icon(new_item)
	dot.show()


func _process(delta: float) -> void:
	if item == "":
		return
	progress += delta
	var dir := Vector2(Defs.DIRS[facing])
	dot.position = dir * (clampf(progress / MOVE_TIME, 0.0, 1.0) - 0.5) * 14.0 + Vector2(0, -3)
	if progress >= MOVE_TIME and game.deliver(cell + Defs.DIRS[facing], item):
		item = ""
		dot.hide()
