class_name Spawner
extends Node
## Spawns each night's wave from the map edges, spread over the night.

@export var crawler_scene: PackedScene
@export var brute_scene: PackedScene

var game: Main
var remaining := 0
var night := 0

@onready var timer: Timer = $SpawnTimer


func _ready() -> void:
	timer.timeout.connect(_on_timeout)


func begin_night(n: int, night_length: float) -> void:
	night = n
	remaining = 8 + n * 5
	timer.start(night_length * 0.8 / remaining)


func end_night() -> void:
	timer.stop()
	remaining = 0
	for e in game.enemies_root.get_children():
		e.queue_free()


func _on_timeout() -> void:
	spawn_enemy()
	remaining -= 1
	if remaining <= 0:
		timer.stop()


func spawn_enemy() -> Enemy:
	var brute := night >= 3 and randf() < 0.25
	var e: Enemy = (brute_scene if brute else crawler_scene).instantiate()
	var size := Vector2(Defs.W, Defs.H) * Defs.TILE
	match randi() % 4:
		0: e.position = Vector2(0, randf() * size.y)
		1: e.position = Vector2(size.x, randf() * size.y)
		2: e.position = Vector2(randf() * size.x, 0)
		_: e.position = Vector2(randf() * size.x, size.y)
	e.game = game
	e.setup(night)
	e.died.connect(game.on_enemy_died)
	game.enemies_root.add_child(e)
	return e
