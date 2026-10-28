class_name FloatingText
extends Node2D
## Floating "+3 Ore" text that rises and fades.

@onready var icon: Sprite2D = $Icon
@onready var label: Label = $Label


func show_at(at: Vector2, text: String, texture: Texture2D = null, tint := Color.WHITE) -> void:
	position = at
	label.text = text
	label.modulate = tint
	icon.texture = texture
	icon.visible = texture != null
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", at.y - 28.0, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.5)
	tween.chain().tween_callback(queue_free)
