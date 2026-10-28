class_name Core
extends Node2D
## The crashed ship. Items delivered to it are stored; if it falls, the run ends.

signal destroyed

@export var max_hp := 500.0

var hp := 0.0

@onready var health_bar: StatBar = $HealthBar


func _ready() -> void:
	hp = max_hp


func take_damage(amount: float) -> void:
	hp = maxf(hp - amount, 0.0)
	health_bar.set_fraction(hp / max_hp)
	if hp <= 0.0:
		destroyed.emit()


func heal(amount: float) -> void:
	hp = minf(hp + amount, max_hp)
	health_bar.set_fraction(hp / max_hp)
