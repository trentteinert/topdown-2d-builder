class_name Drill
extends Building
## Mines the deposit underneath and pushes the output one cell in its facing direction.
## The bit spins while working and stops when the output is blocked.

const INTERVAL := 1.5

var timer := 0.0


func _process(delta: float) -> void:
	timer = minf(timer + delta, INTERVAL)
	if timer < INTERVAL:
		sprite.speed_scale = 1.0
		return
	var deposit := game.world.resource_at(cell)
	if deposit and game.deliver(cell + Defs.DIRS[facing], deposit.item):
		deposit.take()
		timer = 0.0
		body.position.y = 18.0  # little kick when a chunk is ejected
		create_tween().tween_property(body, "position:y", 16.0, 0.12)
	else:
		sprite.speed_scale = 0.0
