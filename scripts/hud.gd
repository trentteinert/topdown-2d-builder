class_name Hud
extends CanvasLayer
## Heads-up display: vitals, resource counters, day/night clock, build hotbar and inventory.
## Runs while the tree is paused so it can show the end screen.

const HOTBAR_TYPES := [Defs.Build.DRILL, Defs.Build.CONVEYOR, Defs.Build.TURRET, Defs.Build.TESLA]
const HOTBAR_SLOT := preload("res://scenes/ui/hotbar_slot.tscn")
const INV_SLOT := preload("res://scenes/ui/inv_slot.tscn")
const COUNTER := preload("res://scenes/ui/resource_counter.tscn")
const ICON_SUN := preload("res://assets/sprites/ico_sun.png")
const ICON_MOON := preload("res://assets/sprites/ico_moon.png")

var game: Main
var inventory_open := false
var picked := -1
var hovered_type: int = Defs.Build.NONE
var counters := {}
var hotbar_slots := {}
var inv_slots: Array = []

@onready var player_bar: ProgressBar = $Root/Vitals/Rows/PlayerRow/PlayerBar
@onready var core_bar: ProgressBar = $Root/Vitals/Rows/CoreRow/CoreBar
@onready var counter_row: HBoxContainer = $Root/Resources/Counters
@onready var phase_icon: TextureRect = $Root/Clock/ClockRows/PhaseRow/PhaseIcon
@onready var phase_label: Label = $Root/Clock/ClockRows/PhaseRow/PhaseLabel
@onready var phase_time: Label = $Root/Clock/ClockRows/PhaseRow/PhaseTime
@onready var phase_bar: ProgressBar = $Root/Clock/ClockRows/PhaseBar
@onready var enemy_label: Label = $Root/Clock/ClockRows/EnemyLabel
@onready var build_info: Label = $Root/HotbarPanel/BuildInfo
@onready var hotbar: HBoxContainer = $Root/HotbarPanel/Hotbar
@onready var hints: Label = $Root/Hints
@onready var inventory_panel: PanelContainer = $Root/Inventory
@onready var inv_title: Label = $Root/Inventory/InvRows/InvTitle
@onready var inv_grid: GridContainer = $Root/Inventory/InvRows/Grid
@onready var message: Label = $Root/Message


func bind(g: Main) -> void:
	game = g
	hints.text = "WASD move   Space mine\nLMB shoot / place   RMB remove\nR rotate   Q shoot mode   Tab inventory"
	for id in Items.IDS:
		var c: ResourceCounter = COUNTER.instantiate()
		counter_row.add_child(c)
		c.setup(id)
		counters[id] = c
	for i in HOTBAR_TYPES.size():
		var slot: HotbarSlot = HOTBAR_SLOT.instantiate()
		hotbar.add_child(slot)
		slot.setup(HOTBAR_TYPES[i], str(i + 1))
		slot.pressed.connect(game.builder.set_selected)
		slot.hovered.connect(_on_slot_hovered)
		hotbar_slots[HOTBAR_TYPES[i]] = slot
	hotbar.mouse_exited.connect(_on_slot_hovered.bind(Defs.Build.NONE))
	for i in game.inventory.slots.size():
		var slot: InvSlot = INV_SLOT.instantiate()
		inv_grid.add_child(slot)
		slot.index = i
		slot.clicked.connect(_on_inv_clicked)
		inv_slots.append(slot)
	game.inventory.changed.connect(refresh_inventory)
	game.builder.selection_changed.connect(func(_t): refresh_hotbar())
	refresh_inventory()


func refresh_inventory() -> void:
	for id in counters:
		counters[id].set_amount(game.inventory.count(id))
	for i in inv_slots.size():
		inv_slots[i].show_stack(game.inventory.slots[i], i == picked)
	inv_title.text = "Inventory  %d/%d" % [game.inventory.used_slots(), game.inventory.slots.size()]
	refresh_hotbar()


func refresh_hotbar() -> void:
	for type in hotbar_slots:
		hotbar_slots[type].refresh(game.max_buildable(type), game.builder.selected == type)
	var shown: int = hovered_type if hovered_type != Defs.Build.NONE else game.builder.selected
	if shown == Defs.Build.NONE:
		build_info.text = "Press 1-4 to build, Q to shoot"
	else:
		var parts: PackedStringArray = []
		for id in Defs.COST[shown]:
			parts.append("%d %s" % [Defs.COST[shown][id], Items.display_name(id)])
		build_info.text = "%s  -  %s" % [Defs.NAMES[shown], ", ".join(parts)]


func _on_slot_hovered(type: int) -> void:
	hovered_type = type
	refresh_hotbar()


func _on_inv_clicked(index: int) -> void:
	if picked == -1:
		if not game.inventory.slots[index].is_empty():
			picked = index
	else:
		game.inventory.swap(picked, index)
		picked = -1
	refresh_inventory()


func toggle_inventory(open: bool) -> void:
	inventory_open = open
	inventory_panel.visible = open
	picked = -1
	refresh_inventory()


func _process(_delta: float) -> void:
	if game == null:
		return
	player_bar.value = maxf(game.player.hp, 0.0) / game.player.max_hp
	core_bar.value = game.core.hp / game.core.max_hp
	var dn := game.day_night
	var t := dn.time_in_cycle()
	if dn.is_night:
		phase_icon.texture = ICON_MOON
		phase_label.text = "Night %d/%d" % [dn.night, Main.WIN_NIGHTS]
		phase_bar.value = (t - dn.day_length) / dn.night_length
		phase_time.text = "dawn %ds" % ceili(dn.cycle_length() - t)
	else:
		phase_icon.texture = ICON_SUN
		phase_label.text = "Day %d" % (dn.night + 1)
		phase_bar.value = t / dn.day_length
		phase_time.text = "night %ds" % ceili(dn.day_length - t)
	enemy_label.text = "Enemies: %d" % game.enemies_root.get_child_count()


func show_message(text: String) -> void:
	message.text = text
	message.show()


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	if message.visible:
		if ev.keycode == KEY_ENTER:
			get_tree().paused = false
			get_tree().reload_current_scene()
		return
	if ev.keycode == KEY_TAB or ev.keycode == KEY_I:
		toggle_inventory(not inventory_open)
	elif ev.keycode == KEY_ESCAPE and inventory_open:
		toggle_inventory(false)
