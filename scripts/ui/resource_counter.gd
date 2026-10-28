class_name ResourceCounter
extends HBoxContainer
## Icon + running total for one item type. Bumps when the value changes.

var item := ""
var shown := -1

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $Count


func setup(id: String) -> void:
	item = id
	icon.texture = Items.icon(id)
	count_label.add_theme_color_override("font_color", Items.color(id))


func set_amount(n: int) -> void:
	if n == shown:
		return
	var grew := shown >= 0 and n > shown
	shown = n
	count_label.text = str(n)
	if grew:
		pivot_offset = size / 2.0
		scale = Vector2(1.25, 1.25)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.2)
