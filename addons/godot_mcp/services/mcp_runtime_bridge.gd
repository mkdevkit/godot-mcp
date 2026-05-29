extends Node
## Runtime bridge autoload — handles in-game MCP requests via user:// IPC.

const NodeUtils = preload("res://addons/godot_mcp/utils/node_utils.gd")
const TypeParser = preload("res://addons/godot_mcp/utils/type_parser.gd")

const REQUEST_FILE := "mcp_runtime_req.json"
const RESPONSE_FILE := "mcp_runtime_res.json"

var _recording: Array = []
var _is_recording := false
var _handling := false


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _handling:
		return
	var path := _user_path(REQUEST_FILE)
	if not FileAccess.file_exists(path):
		return
	_handling = true
	var text := FileAccess.get_file_as_string(path)
	DirAccess.remove_absolute(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		_write_response({"error": "bad request json"})
		_handling = false
		return
	_handle_request(json.data)


func _handle_request(req: Dictionary) -> void:
	var result: Dictionary = await _dispatch_async(req)
	_write_response(result)
	_handling = false


func _dispatch_async(req: Dictionary) -> Dictionary:
	var action: String = req.get("action", "")
	var params: Dictionary = req.get("params", {})
	match action:
		"get_scene_tree":
			var root := get_tree().current_scene
			if root == null:
				return {"error": "no current scene"}
			return {"result": NodeUtils.tree_dict(root)}
		"get_node_properties":
			var node := NodeUtils.resolve_in_tree(get_tree().root, params.get("node_path", ""))
			if node == null:
				return {"error": "node not found"}
			return {"result": _props(node)}
		"set_node_property":
			var node := NodeUtils.resolve_in_tree(get_tree().root, params.get("node_path", ""))
			if node == null:
				return {"error": "node not found"}
			var prop: String = params.get("property", "")
			node.set(prop, _parse(params.get("value", "")))
			return {"result": {"ok": true}}
		"execute_script":
			var expr := Expression.new()
			if expr.parse(params.get("code", "")) != OK:
				return {"error": expr.get_error_text()}
			var node := get_tree().current_scene
			var val = expr.execute([], node, false)
			if expr.has_execute_failed():
				return {"error": expr.get_error_text()}
			return {"result": str(val)}
		"find_by_script":
			var results: Array = []
			NodeUtils.find_by_script(get_tree().root, params.get("script_path", ""), results)
			return {"result": results}
		"find_ui":
			var results: Array = []
			_collect_ui(get_tree().root, results)
			return {"result": results}
		"click_button":
			var text: String = params.get("text", "")
			var btn := _find_button(get_tree().root, text)
			if btn == null:
				return {"error": "button not found"}
			btn.pressed.emit()
			return {"result": {"clicked": btn.name}}
		"wait_for_node":
			var node := NodeUtils.resolve_in_tree(get_tree().root, params.get("node_path", ""))
			return {"result": {"found": node != null}}
		"get_autoload":
			var name: String = params.get("name", "")
			var n := get_node_or_null("/root/%s" % name)
			if n == null:
				return {"error": "autoload not found"}
			return {"result": _props(n)}
		"batch_get_properties":
			var out: Array = []
			for item in params.get("nodes", []):
				var node := NodeUtils.resolve_in_tree(get_tree().root, item.get("path", ""))
				if node:
					out.append({"path": str(node.get_path()), "properties": _props(node, item.get("properties", []))})
			return {"result": out}
		"record_input":
			_is_recording = params.get("enabled", true)
			if not _is_recording:
				var data := _recording.duplicate()
				_recording.clear()
				return {"result": {"events": data}}
			return {"result": {"recording": true}}
		"replay_input":
			for ev in params.get("events", []):
				_replay_event(ev)
			return {"result": {"replayed": true}}
		"watch_signals":
			return await _watch_signals(params)
		_:
			return {"error": "unknown action: %s" % action}


func _watch_signals(params: Dictionary) -> Dictionary:
	var node_paths: Array = params.get("node_paths", [])
	var duration_ms: int = int(params.get("duration_ms", 5000))
	var signal_filter: Array = params.get("signal_filter", [])
	var emissions: Array = []
	var connections: Array = []
	for path_str in node_paths:
		var node := NodeUtils.resolve_in_tree(get_tree().root, str(path_str))
		if node == null:
			continue
		for sig_info in node.get_signal_list():
			var sig_name: String = sig_info.name
			if not signal_filter.is_empty() and sig_name not in signal_filter:
				continue
			var callable := _on_signal_emitted.bind(emissions, str(path_str), sig_name)
			node.connect(sig_name, callable)
			connections.append({"node": node, "signal": sig_name, "callable": callable})
	await get_tree().create_timer(maxf(duration_ms / 1000.0, 0.1)).timeout
	for conn in connections:
		var n: Node = conn.node
		if is_instance_valid(n) and n.is_connected(conn.signal, conn.callable):
			n.disconnect(conn.signal, conn.callable)
	return {"result": {"emissions": emissions, "count": emissions.size(), "duration_ms": duration_ms}}


func _on_signal_emitted(emissions: Array, node_path: String, signal_name: String, *args) -> void:
	var serialized: Array = []
	for arg in args:
		serialized.append(str(arg))
	emissions.append({"node_path": node_path, "signal": signal_name, "args": serialized})


func _props(node: Node, keys: Array = []) -> Dictionary:
	var out := {}
	if keys.is_empty():
		for info in node.get_property_list():
			if info.usage & PROPERTY_USAGE_EDITOR:
				out[info.name] = str(node.get(info.name))
	else:
		for k in keys:
			out[str(k)] = str(node.get(str(k)))
	return out


func _parse(text: String) -> Variant:
	return TypeParser.parse(text)


func _collect_ui(node: Node, results: Array) -> void:
	if node is Control:
		results.append({
			"path": str(node.get_path()),
			"type": node.get_class(),
			"text": node.text if "text" in node else "",
		})
	for child in node.get_children():
		_collect_ui(child, results)


func _find_button(node: Node, text: String) -> BaseButton:
	if node is BaseButton and (text.is_empty() or node.text == text):
		return node
	for child in node.get_children():
		var found := _find_button(child, text)
		if found:
			return found
	return null


func _replay_event(ev: Dictionary) -> void:
	if ev.get("type") == "action":
		Input.action_press(ev.get("action", ""))
		Input.action_release(ev.get("action", ""))


func _user_path(file: String) -> String:
	return OS.get_user_data_dir().path_join(file)


func _write_response(data: Dictionary) -> void:
	var file := FileAccess.open(_user_path(RESPONSE_FILE), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
