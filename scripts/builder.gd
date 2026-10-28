class_name Builder
extends Node2D
## Build-mode input: hotbar selection, ghost preview, placing and removing.

const RANGES := {Defs.Build.TURRET: 260.0, Defs.Build.TESLA: 150.0}

var game: Main
var selected: int = Defs.Build.NONE
var facing := 0
var last_cell := Vector2i(-1, -1)
var lmb_prev := false
var rmb_prev := false
var ring_radius := 0.0

@onready var ghost: ColorRect = $Ghost
@onready var arrow: Polygon2D = $Arrow
@onready var ring: Line2D = $RangeRing


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	match ev.keycode:
		KEY_1: selected = Defs.Build.DRILL
		KEY_2: selected = Defs.Build.CONVEYOR
		KEY_3: selected = Defs.Build.TURRET
		KEY_4: selected = Defs.Build.TESLA
		KEY_Q: selected = Defs.Build.NONE
		KEY_R: facing = (facing + 1) % 4


func _process(_delta: float) -> void:
	var mouse := get_global_mouse_position()
	var cell := Defs.world_to_cell(mouse)
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var rmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if lmb:
		if selected == Defs.Build.NONE:
			game.player.shoot_at(mouse)
		elif not lmb_prev or (selected == Defs.Build.CONVEYOR and cell != last_cell):
			game.try_place(cell, selected, facing)
			last_cell = cell
	if rmb and (not rmb_prev or cell != last_cell):
		game.remove_building(cell)
		last_cell = cell
	lmb_prev = lmb
	rmb_prev = rmb
	_update_ghost(cell)


func _update_ghost(cell: Vector2i) -> void:
	var active := selected != Defs.Build.NONE
	ghost.visible = active
	arrow.visible = active and (selected == Defs.Build.CONVEYOR or selected == Defs.Build.DRILL)
	ring.visible = active and RANGES.has(selected)
	if not active:
		return
	ghost.position = Vector2(cell) * Defs.TILE
	ghost.color = Color(0.3, 1.0, 0.4, 0.45) if game.can_place(cell, selected) else Color(1.0, 0.3, 0.3, 0.45)
	arrow.position = Defs.cell_center(cell)
	arrow.rotation = facing * PI / 2.0
	if ring.visible:
		ring.position = Defs.cell_center(cell)
		_set_ring_radius(RANGES[selected])


func _set_ring_radius(radius: float) -> void:
	if is_equal_approx(ring_radius, radius):
		return
	ring_radius = radius
	var pts := PackedVector2Array()
	for i in 49:
		pts.append(Vector2.from_angle(TAU * i / 48.0) * radius)
	ring.points = pts
