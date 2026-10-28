class_name Zap
extends Line2D
## One short-lived lightning bolt between two points.


func setup(from: Vector2, to: Vector2) -> void:
	points = PackedVector2Array([from, to])
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
