@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

var _monitors: Dictionary = {}
var _recording: Array = []


func get_commands() -> Dictionary:
	return {
		"get_game_scene_tree": _get_game_scene_tree,
		"get_game_node_properties": _get_game_node_properties,
		"set_game_node_property": _set_game_node_property,
		"execute_game_script": _execute_game_script,
		"capture_frames": _capture_frames,
		"monitor_properties": _monitor_properties,
		"start_recording": _start_recording,
		"stop_recording": _stop_recording,
		"replay_recording": _replay_recording,
		"find_nodes_by_script": _find_nodes_by_script,
		"get_autoload": _get_autoload,
		"batch_get_properties": _batch_get_properties,
		"find_ui_elements": _find_ui_elements,
		"click_button_by_text": _click_button_by_text,
		"wait_for_node": _wait_for_node,
		"find_nearby_nodes": _find_nearby_nodes,
		"navigate_to": _navigate_to,
		"move_to": _move_to,
		"watch_signals": _watch_signals,
	}


func _get_game_scene_tree(_p: Dictionary) -> Dictionary:
	return await _runtime_call("get_scene_tree")


func _get_game_node_properties(p: Dictionary) -> Dictionary:
	return await _runtime_call("get_node_properties", {"node_path": p.get("node_path", "")})


func _set_game_node_property(p: Dictionary) -> Dictionary:
	return await _runtime_call("set_node_property", p)


func _execute_game_script(p: Dictionary) -> Dictionary:
	return await _runtime_call("execute_script", {"code": p.get("code", "")})


func _capture_frames(p: Dictionary) -> Dictionary:
	var count: int = int(p.get("count", 3))
	var frames: Array = []
	for i in count:
		var shot := await _request_screenshot("game")
		frames.append(shot.get("result", shot))
		await editor_plugin.get_tree().create_timer(0.1).timeout
	return _ok({"frames": frames})


func _monitor_properties(p: Dictionary) -> Dictionary:
	var key: String = p.get("key", "default")
	_monitors[key] = p
	return _ok({"monitoring": key})


func _start_recording(_p: Dictionary) -> Dictionary:
	_recording.clear()
	return await _runtime_call("record_input", {"enabled": true})


func _stop_recording(_p: Dictionary) -> Dictionary:
	return await _runtime_call("record_input", {"enabled": false})


func _replay_recording(p: Dictionary) -> Dictionary:
	return await _runtime_call("replay_input", {"events": p.get("events", [])})


func _find_nodes_by_script(p: Dictionary) -> Dictionary:
	return await _runtime_call("find_by_script", {"script_path": _norm_res(p.get("script_path", ""))})


func _get_autoload(p: Dictionary) -> Dictionary:
	return await _runtime_call("get_autoload", {"name": p.get("name", "")})


func _batch_get_properties(p: Dictionary) -> Dictionary:
	return await _runtime_call("batch_get_properties", {"nodes": p.get("nodes", [])})


func _find_ui_elements(_p: Dictionary) -> Dictionary:
	return await _runtime_call("find_ui")


func _click_button_by_text(p: Dictionary) -> Dictionary:
	return await _runtime_call("click_button", {"text": p.get("text", "")})


func _wait_for_node(p: Dictionary) -> Dictionary:
	var timeout: float = float(p.get("timeout", 5.0))
	var elapsed := 0.0
	while elapsed < timeout:
		var res := await _runtime_call("wait_for_node", {"node_path": p.get("node_path", "")}, 1.0)
		if res.has("result") and res["result"].get("found", false):
			return res
		elapsed += 1.0
	return _err("Node did not appear in time")


func _find_nearby_nodes(p: Dictionary) -> Dictionary:
	var pos := Vector2(float(p.get("x", 0)), float(p.get("y", 0)))
	var radius: float = float(p.get("radius", 100))
	var tree_res := await _runtime_call("get_scene_tree")
	if tree_res.has("error"):
		return tree_res
	return _ok({"position": str(pos), "radius": radius, "note": "Use get_game_scene_tree and filter by position"})


func _navigate_to(p: Dictionary) -> Dictionary:
	return await _runtime_call("execute_script", {
		"code": "get_node('%s').target_position = Vector2(%s, %s)" % [
			p.get("agent_path", "."), p.get("x", 0), p.get("y", 0)
		]
	})


func _move_to(p: Dictionary) -> Dictionary:
	return _navigate_to(p)


func _watch_signals(p: Dictionary) -> Dictionary:
	var duration_ms: int = int(p.get("duration_ms", 5000))
	var timeout_sec: float = duration_ms / 1000.0 + 3.0
	return await _runtime_call("watch_signals", p, timeout_sec)
