class_name Player
extends Node2D
## The survivor. 3/4-view sprite that faces where you aim; moves, mines and shoots.

@export var speed := 190.0
@export var max_hp := 100.0
@export var bullet_scene: PackedScene

var game: Main
var hp := 0.0
var alive := true
var respawn_timer := 0.0
var shoot_cooldown := 0.0
var mine_cooldown := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var gun_pivot: Node2D = $GunPivot
@onready var gun: Sprite2D = $GunPivot/Gun
@onready var flash: Sprite2D = $GunPivot/Flash
@onready var beam: Line2D = $MineBeam
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
	var aim := get_global_mouse_position() - gun_pivot.global_position
	gun_pivot.rotation = aim.angle()
	gun.flip_v = absf(aim.angle()) > PI / 2.0
	_update_animation(d, aim)
	shoot_cooldown -= delta
	mine_cooldown -= delta
	if Input.is_key_pressed(KEY_SPACE) and not game.hud.inventory_open:
		_mine()
	else:
		beam.hide()


func _update_animation(move: Vector2, aim: Vector2) -> void:
	var view := "side"
	if absf(aim.y) > absf(aim.x) * 1.2:
		view = "down" if aim.y > 0.0 else "up"
	sprite.flip_h = view == "side" and aim.x < 0.0
	gun_pivot.show_behind_parent = view == "up"
	var anim := "%s_%s" % ["walk" if move != Vector2.ZERO else "idle", view]
	if sprite.animation != anim:
		sprite.play(anim)


func _mine() -> void:
	var deposit := game.world.nearest_resource(position, 70.0)
	if deposit == null:
		beam.hide()
		return
	beam.points = PackedVector2Array([gun_pivot.position, to_local(deposit.global_position + Vector2(0, -6))])
	beam.show()
	if mine_cooldown > 0.0:
		return
	var item := deposit.item
	var at := deposit.global_position
	if not game.inventory.can_add(item):
		game.notify_full(position)
		mine_cooldown = 0.5
		return
	deposit.take()
	game.add_item(item)
	game.notify_pickup(item, 1, at)
	game.spawn_poof(at + Vector2(0, 4), Items.color(item), 4)
	mine_cooldown = 0.2


func shoot_at(target: Vector2) -> void:
	if not alive or shoot_cooldown > 0.0:
		return
	shoot_cooldown = 0.16
	var dir := (target - gun_pivot.global_position).normalized()
	var b: Bullet = bullet_scene.instantiate()
	game.projectiles.add_child(b)
	b.launch(gun_pivot.global_position + dir * 24.0, dir, 620.0, 9.0, 0.9)
	flash.show()
	get_tree().create_timer(0.05).timeout.connect(flash.hide)
	gun.position = Vector2(-3, 0)
	create_tween().tween_property(gun, "position", Vector2.ZERO, 0.08)


func take_damage(amount: float) -> void:
	hp -= amount
	shake(5.0, 0.2)
	sprite.modulate = Color(2.5, 1.2, 1.2)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if hp <= 0.0 and alive:
		alive = false
		visible = false
		beam.hide()
		respawn_timer = 4.0
		game.spawn_poof(position + Vector2(0, -12), Color(0.9, 0.95, 1.0), 14)


func respawn() -> void:
	hp = max_hp
	alive = true
	visible = true
	position = Defs.cell_center(Defs.CORE_CELL + Vector2i(0, 4))


func shake(amount: float, duration := 0.2) -> void:
	var tween := create_tween()
	tween.tween_method(func(f: float): camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amount * (1.0 - f), 0.0, 1.0, duration)
	tween.tween_callback(func(): camera.offset = Vector2.ZERO)
