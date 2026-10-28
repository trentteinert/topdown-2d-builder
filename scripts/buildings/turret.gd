class_name GunTurret
extends AmmoBuilding
## Fires bullets at the nearest enemy.

@export var bullet_scene: PackedScene


func _fire(targets_in_range: Array) -> void:
	var dir: Vector2 = (targets_in_range[0].global_position - global_position).normalized()
	pivot.rotation = dir.angle()
	var b: Bullet = bullet_scene.instantiate()
	game.projectiles.add_child(b)
	b.launch(global_position + dir * 14.0, dir, 560.0, 10.0, 0.7)
