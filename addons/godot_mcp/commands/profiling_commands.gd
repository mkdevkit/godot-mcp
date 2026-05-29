@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"get_performance_monitors": _get_performance_monitors,
		"get_editor_performance": _get_editor_performance,
	}


func _get_performance_monitors(_p: Dictionary) -> Dictionary:
	var monitors := {}
	for i in range(Performance.MONITOR_MAX):
		var name := Performance.get_monitor_name(i)
		monitors[name] = Performance.get_monitor(i)
	return _ok({"monitors": monitors})


func _get_editor_performance(_p: Dictionary) -> Dictionary:
	return _ok({
		"fps": Engine.get_frames_per_second(),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS),
		"memory_static": Performance.get_monitor(Performance.MEMORY_STATIC),
		"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
	})
