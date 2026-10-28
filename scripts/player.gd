class_name Player
extends Node2D
## The survivor: moves, mines nearby deposits and shoots.

@export var speed := 190.0
@export var max_hp := 100.0
@export var bullet_scene: PackedScene

var game: Main
var hp := 0.0
var alive := true
var respawn_timer := 0.0
var shoot_cooldown := 0.0
var mine_cooldown := 0.0

@onready var gun: Sprite2D = $Gun
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	hp = max_hp
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = Defs.W * Defs.TILE
	camera.limit_bottom = Defs.H * Defs.TILE


func _process(delta: float) -> void:
	if not alive:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			respawn()
		return
	var d := Vector2(
		int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A)),
		int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W)))
	position += d.normalized() * speed * delta
	position = position.clamp(Vector2(8, 8), Vector2(Defs.W, Defs.H) * Defs.TILE - Vector2(8, 8))
	gun.rotation = (get_global_mouse_position() - global_position).angle()
	gun.flip_v = absf(gun.rotation) > PI / 2.0
	shoot_cooldown -= delta
	mine_cooldown -= delta
	if Input.is_key_pressed(KEY_SPACE) and mine_cooldown <= 0.0:
		mine()


func mine() -> void:
	var deposit := game.world.nearest_resource(position, 70.0)
	if deposit:
		game.add_item(deposit.take())
		mine_cooldown = 0.2


func shoot_at(target: Vector2) -> void:
	if not alive or shoot_cooldown > 0.0:
		return
	shoot_cooldown = 0.16
	var dir := (target - position).normalized()
	var b: Bullet = bullet_scene.instantiate()
	game.projectiles.add_child(b)
	b.launch(position + dir * 14.0, dir, 620.0, 9.0, 0.9)


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		alive = false
		visible = false
		respawn_timer = 4.0


func respawn() -> void:
	hp = max_hp
	alive = true
	visible = true
	position = Defs.cell_center(Defs.CORE_CELL + Vector2i(0, 3))
