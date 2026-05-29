@tool
extends Node
class_name MCPBaseCommands

const NodeUtils = preload("res://addons/godot_mcp/utils/node_utils.gd")
const ResourceUtils = preload("res://addons/godot_mcp/utils/resource_utils.gd")
const TypeParser = preload("res://addons/godot_mcp/utils/type_parser.gd")

var editor_plugin: EditorPlugin

const RUNTIME_REQ := "mcp_runtime_req.json"
const RUNTIME_RES := "mcp_runtime_res.json"
const SCREENSHOT_REQ := "mcp_screenshot_req.json"
const SCREENSHOT_RES := "mcp_screenshot_res.png"
const SCREENSHOT_META := "mcp_screenshot_meta.json"


func get_commands() -> Dictionary:
	return {}


func _ok(result: Variant = {}) -> Dictionary:
	return {"result": result}


func _err(message: String, code: int = -32000, data: Dictionary = {}) -> Dictionary:
	return {"error": {"code": code, "message": message, "data": data}}


func _edited_root() -> Node:
	return editor_plugin.get_editor_interface().get_edited_scene_root()


func _resolve_node(path: String) -> Node:
	return NodeUtils.resolve_in_tree(_edited_root(), path)


func _norm_res(path: String) -> String:
	return ResourceUtils.normalize_res(path)


func _user_file(name: String) -> String:
	return OS.get_user_data_dir().path_join(name)


func _runtime_call(action: String, params: Dictionary = {}, timeout_sec: float = 5.0) -> Dictionary:
	if not editor_plugin.get_editor_interface().is_playing_scene():
		return _err("Game is not running. Use play_scene first.", -32010)
	var req_path := _user_file(RUNTIME_REQ)
	var res_path := _user_file(RUNTIME_RES)
	if FileAccess.file_exists(res_path):
		DirAccess.remove_absolute(res_path)
	var file := FileAccess.open(req_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"action": action, "params": params}))
	file.close()
	var elapsed := 0.0
	while elapsed < timeout_sec:
		await editor_plugin.get_tree().create_timer(0.05).timeout
		elapsed += 0.05
		if FileAccess.file_exists(res_path):
			var text := FileAccess.get_file_as_string(res_path)
			DirAccess.remove_absolute(res_path)
			var data = JSON.parse_string(text)
			if data is Dictionary:
				if data.has("error"):
					return _err(str(data["error"]))
				return _ok(data.get("result", data))
	return _err("Runtime request timed out", -32011)


func _queue_input(events: Array) -> void:
	var bridge = _get_input_bridge()
	if bridge:
		bridge.queue_events(events)


func _get_input_bridge() -> Node:
	return get_node_or_null("/root/MCPInputBridge")


func _request_screenshot(target: String = "editor") -> Dictionary:
	var req_path := _user_file(SCREENSHOT_REQ)
	var res_path := _user_file(SCREENSHOT_RES)
	var meta_path := _user_file(SCREENSHOT_META)
	if FileAccess.file_exists(res_path):
		DirAccess.remove_absolute(res_path)
	var file := FileAccess.open(req_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"target": target}))
	file.close()
	if target == "editor":
		var vp := editor_plugin.get_editor_interface().get_editor_main_screen().get_viewport()
		if vp:
			var img := vp.get_texture().get_image()
			if img:
				img.save_png(res_path)
				return _ok({"path": res_path, "width": img.get_width(), "height": img.get_height(), "base64": Marshalls.raw_to_base64(img.save_png_to_buffer())})
	var elapsed := 0.0
	while elapsed < 5.0:
		await editor_plugin.get_tree().create_timer(0.1).timeout
		elapsed += 0.1
		if FileAccess.file_exists(res_path):
			var img := Image.load_from_file(res_path)
			var meta := {}
			if FileAccess.file_exists(meta_path):
				meta = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
			return _ok({
				"path": res_path,
				"width": img.get_width() if img else 0,
				"height": img.get_height() if img else 0,
				"base64": Marshalls.raw_to_base64(img.save_png_to_buffer()) if img else "",
				"meta": meta,
			})
	return _err("Screenshot capture failed")


func _undo_property(node: Object, property: String, new_value: Variant) -> void:
	var old_value = node.get(property)
	editor_plugin.get_undo_redo().create_action("MCP Set %s" % property)
	editor_plugin.get_undo_redo().add_do_property(node, property, new_value)
	editor_plugin.get_undo_redo().add_undo_property(node, property, old_value)
	editor_plugin.get_undo_redo().commit_action()


func _parse_value(text: String) -> Variant:
	return TypeParser.parse(text)


func _node_to_dict(node: Node, depth: int = 0, max_depth: int = 8) -> Dictionary:
	var info := {
		"name": node.name,
		"type": node.get_class(),
		"path": str(node.get_path()),
	}
	if depth < max_depth:
		var children: Array = []
		for child in node.get_children():
			children.append(_node_to_dict(child, depth + 1, max_depth))
		info["children"] = children
	return info


func _serialize_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_VECTOR2:
			return "Vector2(%s, %s)" % [value.x, value.y]
		TYPE_VECTOR3:
			return "Vector3(%s, %s, %s)" % [value.x, value.y, value.z]
		TYPE_VECTOR2I:
			return "Vector2i(%s, %s)" % [value.x, value.y]
		TYPE_VECTOR3I:
			return "Vector3i(%s, %s, %s)" % [value.x, value.y, value.z]
		TYPE_RECT2:
			return "Rect2(%s, %s, %s, %s)" % [value.position.x, value.position.y, value.size.x, value.size.y]
		TYPE_COLOR:
			return "Color(%s, %s, %s, %s)" % [value.r, value.g, value.b, value.a]
		TYPE_OBJECT:
			if value == null:
				return null
			if value is Node:
				return str(value.get_path())
			if value is Resource:
				return value.resource_path if value.resource_path else str(value)
			return str(value)
		TYPE_ARRAY:
			var arr: Array = []
			for item in value:
				arr.append(_serialize_value(item))
			return arr
		TYPE_DICTIONARY:
			var dict := {}
			for key in value:
				dict[str(key)] = _serialize_value(value[key])
			return dict
		_:
			return str(value)
