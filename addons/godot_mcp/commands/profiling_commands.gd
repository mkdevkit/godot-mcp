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
		var key := _monitor_name(i)
		monitors[key] = Performance.get_monitor(i)
	return _ok({"monitors": monitors})


func _monitor_name(monitor_id: int) -> String:
	var names := [
		"time/fps", "time/process", "time/physics_process", "time/navigation_process",
		"memory/static", "memory/static_max", "memory/msg_buf_max",
		"object/objects", "object/resources", "object/nodes", "object/orphan_nodes",
		"raster/total_objects_drawn", "raster/total_primitives_drawn", "raster/total_draw_calls",
		"video/video_mem", "video/texture_mem", "video/buffer_mem",
		"physics_2d/active_objects", "physics_2d/collision_pairs", "physics_2d/islands",
		"physics_3d/active_objects", "physics_3d/collision_pairs", "physics_3d/islands",
		"audio/driver/output_latency", "audio/driver/output_latency_raw",
	]
	if monitor_id >= 0 and monitor_id < names.size():
		return names[monitor_id]
	return "monitor_%d" % monitor_id


func _get_editor_performance(_p: Dictionary) -> Dictionary:
	return _ok({
		"fps": Engine.get_frames_per_second(),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS),
		"memory_static": Performance.get_monitor(Performance.MEMORY_STATIC),
		"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
	})
