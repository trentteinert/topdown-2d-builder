class_name Drill
extends Building
## Mines the deposit underneath and pushes the output one cell in its facing direction.

const INTERVAL := 1.5

var timer := 0.0


func _process(delta: float) -> void:
	timer = minf(timer + delta, INTERVAL)
	if timer < INTERVAL:
		return
	var deposit := game.world.resource_at(cell)
	if deposit and game.deliver(cell + Defs.DIRS[facing], deposit.item):
		deposit.take()
		timer = 0.0
