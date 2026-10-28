class_name Hud
extends CanvasLayer
## Heads-up display. Keeps running while the tree is paused so it can show the end screen.

@onready var status: Label = $Margin/Layout/Status
@onready var resources: Label = $Margin/Layout/Resources
@onready var vitals: Label = $Margin/Layout/Vitals
@onready var selection: Label = $Margin/Layout/Selection
@onready var hints: Label = $Margin/Layout/Hints
@onready var message: Label = $Message


func _ready() -> void:
	hints.text = "[1] Drill 10 ore   [2] Conveyor 1 ore   [3] Gun turret 15 ore (fed ore)   [4] Tesla coil 10 ore + 8 crystal (fed crystal)\n" \
		+ "WASD move   Space mine   LMB shoot / place   RMB remove   R rotate   Q shoot mode"


func update_status(phase: String, inv: Dictionary, kills: int, core_hp: float, core_max: float, player_hp: float, selected_text: String) -> void:
	status.text = phase
	resources.text = "Ore %d   Crystal %d   Kills %d" % [inv.ore, inv.crystal, kills]
	vitals.text = "Core %d/%d   You %d" % [core_hp, core_max, maxf(player_hp, 0.0)]
	selection.text = "Build: " + selected_text


func show_message(text: String) -> void:
	message.text = text
	message.show()


func _unhandled_input(ev: InputEvent) -> void:
	if message.visible and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ENTER:
		get_tree().paused = false
		get_tree().reload_current_scene()
