class_name Enemy
extends Area2D
## Walks toward the player (if close) or the core, chewing through anything in the way.

signal died(enemy: Enemy)

@export var max_hp := 20.0
@export var hp_per_night := 3.0
@export var speed := 65.0
@export var speed_per_night := 3.0
@export var damage := 6.0

var game: Main
var hp := 0.0
var cooldown := 0.0
var dead := false

@onready var health_bar: StatBar = $HealthBar
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	hp = max_hp


func setup(night: int) -> void:
	max_hp += hp_per_night * night
	speed += speed_per_night * night
	hp = max_hp


func take_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount
	health_bar.show()
	health_bar.set_fraction(hp / max_hp)
	sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if hp <= 0.0:
		dead = true
		died.emit(self)
		queue_free()


func _process(delta: float) -> void:
	cooldown -= delta
	var player := game.player
	var target := game.core.position
	if player.alive and position.distance_to(player.position) < 180.0:
		target = player.position
	var dir := (target - position).normalized()
	if absf(dir.x) > 0.05:
		sprite.flip_h = dir.x < 0.0
	var ahead := Defs.world_to_cell(position + dir * 16.0)
	if Defs.is_core(ahead):
		_attack(game.core)
	elif game.building_at(ahead):
		_attack(game.building_at(ahead))
	else:
		position += dir * speed * delta
		sprite.speed_scale = 1.0
	if player.alive and position.distance_to(player.position) < 20.0:
		_attack(player)


func _attack(victim: Node) -> void:
	sprite.speed_scale = 0.0
	if cooldown > 0.0:
		return
	cooldown = 0.8
	victim.take_damage(damage)
	sprite.scale = Vector2(1.3, 0.75)  # lunge: squash then spring back
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
