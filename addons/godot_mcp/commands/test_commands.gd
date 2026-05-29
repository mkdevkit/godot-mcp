@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

var _test_results: Array = []
var _stress_running := false


func get_commands() -> Dictionary:
	return {
		"run_test_scenario": _run_test_scenario,
		"assert_node_state": _assert_node_state,
		"assert_screen_text": _assert_screen_text,
		"run_stress_test": _run_stress_test,
		"get_test_report": _get_test_report,
	}


func _run_test_scenario(p: Dictionary) -> Dictionary:
	var steps: Array = p.get("steps", [])
	var results: Array = []
	for step in steps:
		var action: String = step.get("action", "")
		var result := {"action": action, "ok": true}
		match action:
			"play":
				await _play_scene.call({"mode": "current"})
			"stop":
				await _stop_scene.call({})
			"wait":
				await editor_plugin.get_tree().create_timer(float(step.get("seconds", 1.0))).timeout
			"assert_node":
				var node := _resolve_node(step.get("node_path", ""))
				result["ok"] = node != null
		results.append(result)
	_test_results = results
	return _ok({"steps_run": results.size(), "results": results})


func _play_scene(params: Dictionary) -> Dictionary:
	editor_plugin.get_editor_interface().play_current_scene()
	return _ok({})


func _stop_scene(_p: Dictionary) -> Dictionary:
	editor_plugin.get_editor_interface().stop_playing_scene()
	return _ok({})


func _assert_node_state(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _ok({"passed": false, "reason": "node not found"})
	var prop: String = p.get("property", "")
	var expected = _parse_value(str(p.get("expected", "")))
	var actual = node.get(prop)
	var passed := str(actual) == str(expected)
	_test_results.append({"assert_node_state": passed})
	return _ok({"passed": passed, "expected": str(expected), "actual": str(actual)})


func _assert_screen_text(p: Dictionary) -> Dictionary:
	var text: String = p.get("text", "")
	if editor_plugin.get_editor_interface().is_playing_scene():
		var res := await _runtime_call("find_ui")
		if res.has("result"):
			for item in res["result"]:
				if str(item.get("text", "")).contains(text):
					return _ok({"passed": true, "found": item})
	return _ok({"passed": false, "text": text})


func _run_stress_test(p: Dictionary) -> Dictionary:
	var duration: float = float(p.get("duration", 5.0))
	_stress_running = true
	var start_fps := Engine.get_frames_per_second()
	await editor_plugin.get_tree().create_timer(duration).timeout
	_stress_running = false
	return _ok({
		"duration": duration,
		"start_fps": start_fps,
		"end_fps": Engine.get_frames_per_second(),
	})


func _get_test_report(_p: Dictionary) -> Dictionary:
	return _ok({"results": _test_results, "stress_running": _stress_running})
