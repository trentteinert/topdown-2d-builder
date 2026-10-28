class_name GunTurret
extends AmmoBuilding
## Fires bullets at the nearest enemy; the barrel swings to aim and kicks back on each shot.

@export var bullet_scene: PackedScene

@onready var pivot: Node2D = $Body/Pivot
@onready var barrel: Sprite2D = $Body/Pivot/Barrel
@onready var flash: Sprite2D = $Body/Pivot/Flash


func _fire(targets_in_range: Array) -> void:
	var from := pivot.global_position
	var dir: Vector2 = (targets_in_range[0].global_position + Vector2(0, -8) - from).normalized()
	pivot.rotation = dir.angle()
	var b: Bullet = bullet_scene.instantiate()
	game.projectiles.add_child(b)
	b.launch(from + dir * 24.0, dir, 560.0, 10.0, 0.8)
	flash.show()
	get_tree().create_timer(0.06).timeout.connect(flash.hide)
	barrel.position = Vector2(-4, 0)
	create_tween().tween_property(barrel, "position", Vector2.ZERO, 0.12)
