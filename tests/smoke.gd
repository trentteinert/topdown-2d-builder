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


func _initialize() -> void:
	var main: Main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	Engine.time_scale = 8.0

	check(main.world.deposits.size() > 20, "world has deposits (%d)" % main.world.deposits.size())

	# Drill -> conveyor x3 -> core delivers ore.
	main.inv.ore = 200
	main.world.spawn_deposit(Vector2i(50, 30), "ore", 5)
	check(main.try_place(Vector2i(50, 30), Defs.Build.DRILL, 2), "place drill on ore")
	check(not main.try_place(Vector2i(60, 5), Defs.Build.DRILL, 0) or main.world.resource_at(Vector2i(60, 5)) != null, "drill needs ore")
	for x in [49, 48, 47]:
		check(main.try_place(Vector2i(x, 30), Defs.Build.CONVEYOR, 2), "place conveyor at %d" % x)
	var before: int = main.inv.ore
	var delivered := await wait_until(func(): return main.inv.ore > before)
	check(delivered, "factory delivered ore to core (%d -> %d)" % [before, main.inv.ore])

	# Turret fed by a drill+conveyor line, plus a tesla coil, defend against a wave.
	check(main.try_place(Vector2i(40, 26), Defs.Build.TURRET, 0), "place turret")
	main.inv.crystal = 20
	check(main.try_place(Vector2i(40, 34), Defs.Build.TESLA, 0), "place tesla coil")
	main.day_night.clock = main.day_night.day_length + 1.0
	await process_frame
	check(main.day_night.is_night, "night starts")
	for i in 12:
		var e := main.spawner.spawn_enemy()
		e.position = Defs.cell_center(Vector2i(35, 30)) + Vector2(randf() * 40.0, randf() * 40.0)
	var killed := await wait_until(func(): return main.kills >= 6)
	check(killed, "defences killed enemies (%d kills)" % main.kills)

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
