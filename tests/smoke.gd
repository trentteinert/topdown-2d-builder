extends SceneTree
## Headless smoke test: godot --headless --path . -s tests/smoke.gd
## Runs the real scene with real frames (time sped up) and checks the core loops.

var failures := 0


func check(cond: bool, what: String) -> void:
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		failures += 1


## Waits for frames until `cond` is true or `seconds` of wall time pass.
func wait_until(cond: Callable, seconds := 25.0) -> bool:
	var start := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - start > seconds * 1000.0:
			return false
		await process_frame
	return true


func test_inventory() -> void:
	var inv := Inventory.new(3)
	check(inv.add("ore", 120) == 0, "inventory: 120 ore fits in 3 slots of 50")
	check(inv.count("ore") == 120 and inv.used_slots() == 3, "inventory: stacks split at 50")
	check(inv.add("ore", 40) == 10, "inventory: overflow is reported (10 left over)")
	check(not inv.can_add("crystal"), "inventory: full inventory refuses a new item type")
	check(inv.remove("ore", 70) and inv.count("ore") == 80, "inventory: remove across stacks")
	check(not inv.pay({"ore": 100}) and inv.count("ore") == 80, "inventory: pay is all-or-nothing")
	inv.add("crystal", 5)
	check(inv.pay({"ore": 30, "crystal": 5}) and inv.count("ore") == 50, "inventory: pay mixed cost")
	var inv2 := Inventory.new(3)
	inv2.add("ore", 30)
	inv2.add("crystal", 5)
	inv2.swap(0, 2)
	check(inv2.slots[2].id == "ore" and inv2.slots[0].is_empty(), "inventory: swap moves a stack")
	inv2.add("ore", 5)
	inv2.swap(1, 2)
	check(inv2.count("ore") == 35, "inventory: swap keeps totals")


func _initialize() -> void:
	test_inventory()
	var main: Main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	Engine.time_scale = 8.0

	check(main.world.deposits.size() > 20, "world has deposits (%d)" % main.world.deposits.size())
	check(main.world.props.size() > 20, "world has decorative props (%d)" % main.world.props.size())
	check(main.get_node("Entities").y_sort_enabled, "entities layer is Y-sorted")
	check(main.hud.hotbar_slots.size() == 4 and main.hud.counters.size() == Items.IDS.size(), "HUD built hotbar and counters")
	check(main.hud.inv_slots.size() == main.inventory.slots.size(), "HUD built inventory grid")
	check(main.inventory.count("ore") == 40, "start with 40 ore")

	# Inventory UI toggles and clicking swaps slots.
	main.hud.toggle_inventory(true)
	main.hud._on_inv_clicked(0)
	main.hud._on_inv_clicked(5)
	check(main.hud.inventory_open and main.inventory.slots[5].id == "ore", "inventory panel opens; click-click moves a stack")
	main.hud.toggle_inventory(false)

	# Building costs come out of the inventory.
	main.inventory.add("ore", 100)
	main.world.spawn_deposit(Vector2i(50, 30), "ore", 5)
	var ore_before: int = main.inventory.count("ore")
	check(main.try_place(Vector2i(50, 30), Defs.Build.DRILL, 2), "place drill on ore")
	check(main.inventory.count("ore") == ore_before - 10, "drill cost paid from inventory")
	check(main.max_buildable(Defs.Build.TESLA) == 0, "tesla coil needs crystal + scrap")
	check(not main.try_place(Vector2i(60, 5), Defs.Build.DRILL, 0) or main.world.resource_at(Vector2i(60, 5)) != null, "drill needs ore")
	for x in [49, 48, 47]:
		check(main.try_place(Vector2i(x, 30), Defs.Build.CONVEYOR, 2), "place conveyor at %d" % x)
	var before: int = main.inventory.count("ore")
	var delivered := await wait_until(func(): return main.inventory.count("ore") > before)
	check(delivered, "factory delivered ore to the core inventory (%d -> %d)" % [before, main.inventory.count("ore")])

	# A full inventory backs the belt up instead of deleting items.
	var full := Inventory.new(1)
	full.add("scrap", 50)
	check(not full.can_add("scrap"), "full stack refuses more")

	# Turret + tesla coil defend against a wave.
	check(main.try_place(Vector2i(40, 26), Defs.Build.TURRET, 0), "place turret")
	main.inventory.add("crystal", 20)
	main.inventory.add("scrap", 10)
	check(main.try_place(Vector2i(40, 34), Defs.Build.TESLA, 0), "place tesla coil")
	main.day_night.clock = main.day_night.day_length + 1.0
	await process_frame
	check(main.day_night.is_night, "night starts")
	for i in 12:
		var e := main.spawner.spawn_enemy()
		e.position = Defs.cell_center(Vector2i(35, 30)) + Vector2(randf() * 40.0, randf() * 40.0)
	var scrap_before: int = main.inventory.count("scrap")
	var killed := await wait_until(func(): return main.kills >= 6)
	check(killed, "defences killed enemies (%d kills)" % main.kills)
	check(main.inventory.count("scrap") > scrap_before, "enemies drop scrap into the inventory")
	check(main.effects.get_child_count() > 0, "death / pickup effects were spawned")

	# Mining shows pickups, and the player can mine a deposit.
	main.player.position = Defs.cell_center(Vector2i(50, 30))
	main.player.mine_cooldown = 0.0
	main.player._mine()
	check(main.player.beam.visible or main.world.nearest_resource(main.player.position, 70.0) == null, "mining beam shows while mining")

	# Dawn clears the night and heals the core.
	main.core.take_damage(50.0)
	main.day_night.clock = main.day_night.cycle_length() - 0.05
	var dawned := await wait_until(func(): return not main.day_night.is_night)
	check(dawned, "dawn ends the night")
	check(main.enemies_root.get_child_count() == 0 or await wait_until(func(): return main.enemies_root.get_child_count() == 0, 2.0), "dawn clears enemies")

	# Losing the core ends the run.
	main.core.take_damage(10000.0)
	check(main.finished and paused, "core destroyed pauses the game")

	Engine.time_scale = 1.0
	quit(1 if failures > 0 else 0)
