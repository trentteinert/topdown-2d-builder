class_name Bullet
extends Area2D
## Straight-line projectile that damages the first enemy it touches.

var velocity := Vector2.ZERO
var damage := 9.0
var life := 0.9


func launch(from: Vector2, dir: Vector2, speed: float, dmg: float, lifetime: float) -> void:
	position = from
	velocity = dir * speed
	damage = dmg
	life = lifetime


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
