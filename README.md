# Stranded Frontier

Top-down 2D space survival + factory game in **Godot 4.3** (GL Compatibility renderer).
Build a factory by day, survive the horde by night.

Open the folder in Godot 4.3+ and press **F5**.

## How to play

| Input | Action |
|---|---|
| WASD | Move |
| Space (hold) | Mine the nearest deposit |
| LMB | Shoot (or place the selected building) |
| RMB | Remove a building (50% refund) |
| 1-4 | Select Drill / Conveyor / Gun turret / Tesla coil |
| R | Rotate placement direction |
| Q | Back to shoot mode |

- **Drills** go on deposits and push output one tile in their facing direction.
- **Conveyors** carry items to the **core** (your crashed ship), or into turrets.
- **Gun turrets** are fed ore; **Tesla coils** are fed crystal (hit up to 3 enemies at once). Without ammo they do nothing, so run belts to them.
- Enemies attack from the map edge every night and chew through whatever is in their way. Survive 8 nights to win; if the core falls, you lose.

## Project layout

Everything is a scene made of nodes; scripts only hold behaviour.

```
main.tscn                 Main (orchestrator) + DayNight, World, Core, Buildings, Enemies, Projectiles, Player, Builder, Spawner, HUD
scenes/
  world.tscn              ColorRect with grid shader, Line2D border, Deposits
  player.tscn core.tscn builder.tscn
  buildings/              conveyor, drill, turret, tesla  (Polygon2D visuals, Area2D range)
  enemies/                enemy (crawler), brute          (Area2D)
  projectiles/            bullet (Area2D), zap (Line2D + Tween)
  deposits/               ore, crystal
  ui/                     hud (CanvasLayer + containers), stat_bar
scripts/                  one script per scene, plus defs.gd (constants/helpers)
shaders/grid.gdshader     tile grid + ground variation
tests/smoke.gd            headless gameplay smoke test
```

Visuals are placeholder `Polygon2D` shapes. To swap in real art, replace those nodes with `Sprite2D`/`AnimatedSprite2D` in the scenes.

## Tests

```bash
godot --headless --path . -s tests/smoke.gd
```
