extends RefCounted

var duration_seconds := 75.0
var time_seconds := 0.0
var running := false

func _init(duration := 75.0) -> void:
	duration_seconds = duration

func start() -> void:
	time_seconds = 0.0
	running = true

func tick(delta_seconds: float) -> void:
	if not running:
		return
	time_seconds = min(time_seconds + max(delta_seconds, 0.0), duration_seconds)
	if is_complete():
		running = false

func is_complete() -> bool:
	return time_seconds >= duration_seconds

