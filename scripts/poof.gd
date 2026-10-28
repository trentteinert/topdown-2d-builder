class_name Poof
extends CPUParticles2D
## One-shot particle burst that frees itself.


func burst(at: Vector2, tint: Color, count := 10) -> void:
	position = at
	color = tint
	amount = count
	emitting = true
	get_tree().create_timer(lifetime + 0.3).timeout.connect(queue_free)
