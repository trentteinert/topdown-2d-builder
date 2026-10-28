class_name HotbarSlot
extends PanelContainer
## One build-menu slot: icon, hotkey and how many you can currently afford.

signal pressed(type: int)
signal hovered(type: int)

var type := Defs.Build.NONE

@onready var icon: TextureRect = $Icon
@onready var key_label: Label = $Overlay/Key
@onready var count_label: Label = $Overlay/Count


func setup(build_type: int, key: String) -> void:
	type = build_type
	key_label.text = key
	if Defs.BUILD_ICONS.has(build_type):
		icon.texture = Defs.BUILD_ICONS[build_type]
	mouse_entered.connect(func(): hovered.emit(type))


func refresh(buildable: int, selected: bool) -> void:
	count_label.text = "x%d" % buildable
	count_label.add_theme_color_override("font_color", Color(0.5, 1, 0.6) if buildable > 0 else Color(1, 0.4, 0.4))
	icon.modulate = Color.WHITE if buildable > 0 else Color(0.5, 0.5, 0.55)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.15, 0.08, 0.95) if selected else Color(0.07, 0.06, 0.11, 0.9)
	sb.border_color = Color(1, 1, 1) if selected else Color(0.96, 0.78, 0.25)
	sb.set_border_width_all(3 if selected else 2)
	sb.set_corner_radius_all(3)
	add_theme_stylebox_override("panel", sb)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(type)
