class_name Core
extends Node2D
## The crashed ship. Items delivered to it go to the inventory; if it falls, the run ends.

signal destroyed
signal damaged(amount: float)

@export var max_hp := 500.0

var hp := 0.0

@onready var health_bar: StatBar = $HealthBar
@onready var sprite: AnimatedSprite2D = $Body/Sprite


func _ready() -> void:
	hp = max_hp


func take_damage(amount: float) -> void:
	hp = maxf(hp - amount, 0.0)
	health_bar.set_fraction(hp / max_hp)
	damaged.emit(amount)
	sprite.modulate = Color(2.2, 1.2, 1.2)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	if hp <= 0.0:
		destroyed.emit()


func heal(amount: float) -> void:
	hp = minf(hp + amount, max_hp)
	health_bar.set_fraction(hp / max_hp)
