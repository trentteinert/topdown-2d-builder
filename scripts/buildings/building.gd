class_name Building
extends Node2D
## Base class for everything placed on the grid. The "Body" child sits on the tile's
## bottom edge, so scaling it pops the building up from its base.

signal destroyed(cell: Vector2i)

@export var max_hp := 40.0
## Pick the sprite animation named after the facing ("e", "s", "w", "n").
@export var facing_animations := false

var game: Main
var type := Defs.Build.NONE
var cell := Vector2i.ZERO
var facing := 0
var hp := 0.0

@onready var health_bar: StatBar = $HealthBar
@onready var body: Node2D = get_node_or_null("Body")
@onready var sprite: AnimatedSprite2D = get_node_or_null("Body/Sprite")


func setup(c: Vector2i, f: int) -> void:
	cell = c
	facing = f
	hp = max_hp
	position = Defs.cell_center(c)
	if facing_animations and sprite:
		sprite.play(Defs.DIR_KEYS[f])
	if body:
		body.scale = Vector2(1.2, 0.55)
		create_tween().tween_property(body, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func accepts(_item: String) -> bool:
	return false


func receive(_item: String) -> void:
	pass


func take_damage(amount: float) -> void:
	hp -= amount
	health_bar.show()
	health_bar.set_fraction(hp / max_hp)
	if body:
		body.modulate = Color(2.5, 1.4, 1.4)
		create_tween().tween_property(body, "modulate", Color.WHITE, 0.15)
	if hp <= 0.0:
		destroyed.emit(cell)
