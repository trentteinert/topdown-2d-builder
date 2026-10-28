class_name TeslaCoil
extends AmmoBuilding
## Zaps several enemies at once from the orb on top of the tower.

const ORB_OFFSET := Vector2(0, -28)

@export var zap_scene: PackedScene
@export var zap_damage := 16.0


func _fire(targets_in_range: Array) -> void:
	for e in targets_in_range:
		e.take_damage(zap_damage)
		var z: Zap = zap_scene.instantiate()
		game.projectiles.add_child(z)
		z.setup(global_position + ORB_OFFSET, e.global_position + Vector2(0, -8))
	body.modulate = Color(1.6, 1.6, 2.2)
	create_tween().tween_property(body, "modulate", Color.WHITE, 0.2)
