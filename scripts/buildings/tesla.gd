class_name TeslaCoil
extends AmmoBuilding
## Zaps several enemies at once, no travel time.

@export var zap_scene: PackedScene
@export var zap_damage := 16.0


func _fire(targets_in_range: Array) -> void:
	for e in targets_in_range:
		e.take_damage(zap_damage)
		var z: Zap = zap_scene.instantiate()
		game.projectiles.add_child(z)
		z.setup(global_position, e.global_position)
