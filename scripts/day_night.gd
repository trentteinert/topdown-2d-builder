class_name DayNight
extends CanvasModulate
## Day/night clock. Tints the whole canvas at dusk and announces night and dawn.

signal night_started(night: int)
signal dawn(night: int)

@export var day_length := 60.0
@export var night_length := 45.0
@export var night_color := Color(0.5, 0.52, 0.82)
@export var fade_time := 4.0

var clock := 0.0
var night := 0
var is_night := false


func cycle_length() -> float:
	return day_length + night_length


func time_in_cycle() -> float:
	return fmod(clock, cycle_length())


func _process(delta: float) -> void:
	clock += delta
	var t := time_in_cycle()
	var night_now := t >= day_length
	if night_now and not is_night:
		is_night = true
		night += 1
		night_started.emit(night)
	elif not night_now and is_night:
		is_night = false
		dawn.emit(night)
	# Dusk fades in over the end of the day, dawn fades out over the end of the night.
	var dark := 0.0
	if night_now:
		dark = clampf((cycle_length() - t) / fade_time, 0.0, 1.0)
	else:
		dark = clampf((t - (day_length - fade_time)) / fade_time, 0.0, 1.0)
	color = Color.WHITE.lerp(night_color, dark)
