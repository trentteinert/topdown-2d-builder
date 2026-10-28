class_name InvSlot
extends PanelContainer
## One inventory cell. Click one slot then another to move / merge stacks.

signal clicked(index: int)

var index := 0

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $Overlay/Count


func show_stack(stack: Dictionary, picked: bool) -> void:
	if stack.is_empty():
		icon.texture = null
		count_label.text = ""
		tooltip_text = ""
	else:
		icon.texture = Items.icon(stack.id)
		count_label.text = str(stack.count)
		tooltip_text = Items.display_name(stack.id)
	modulate = Color(1.4, 1.3, 0.8) if picked else Color.WHITE


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(index)
