@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

var _output_buffer: PackedStringArray = PackedStringArray()


func get_commands() -> Dictionary:
	return {
		"get_editor_errors": _get_editor_errors,
		"get_output_log": _get_output_log,
		"execute_editor_script": _execute_editor_script,
		"clear_output": _clear_output,
		"get_open_scripts": _get_open_scripts,
		"get_editor_screenshot": _get_editor_screenshot,
		"get_game_screenshot": _get_game_screenshot,
		"reload_plugin": _reload_plugin,
		"reload_project": _reload_project,
		"get_editor_camera": _get_editor_camera,
		"set_editor_camera": _set_editor_camera,
		"set_auto_dismiss": _set_auto_dismiss,
		"compare_screenshots": _compare_screenshots,
	}


func append_output(line: String) -> void:
	_output_buffer.append(line)
	if _output_buffer.size() > 2000:
		_output_buffer = _output_buffer.slice(-1500)


func _get_editor_errors(_params: Dictionary) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	for line in _output_buffer:
		var upper := line.to_upper()
		if "ERROR" in upper or "SCRIPT ERROR" in upper or "PARSE ERROR" in upper:
			errors.append(line)
		elif "WARNING" in upper:
			warnings.append(line)
	return _ok({
		"errors": errors,
		"warnings": warnings,
		"error_count": errors.size(),
		"warning_count": warnings.size(),
	})


func _get_output_log(params: Dictionary) -> Dictionary:
	var max_lines: int = int(params.get("max_lines", 200))
	var start := maxi(0, _output_buffer.size() - max_lines)
	var lines := _output_buffer.slice(start)
	return _ok({"lines": Array(lines), "count": lines.size()})


func _execute_editor_script(params: Dictionary) -> Dictionary:
	var code: String = params.get("code", "")
	if code.is_empty():
		return _err("Missing 'code'")

	var expr := Expression.new()
	var err := expr.parse(code)
	if err != OK:
		return _err("Parse error: %s" % expr.get_error_text(), -32003)

	var result: Variant = expr.execute([], _edited_root(), false)
	if expr.has_execute_failed():
		return _err("Execution failed: %s" % expr.get_error_text(), -32003)

	return _ok({"result": _serialize_value(result)})


func _clear_output(_params: Dictionary) -> Dictionary:
	_output_buffer.clear()
	return _ok({"cleared": true})


func _get_open_scripts(_params: Dictionary) -> Dictionary:
	var scripts: Array = []
	var script_editor := editor_plugin.get_editor_interface().get_script_editor()
	if script_editor:
		for script in script_editor.get_open_scripts():
			if script and script.resource_path:
				scripts.append(script.resource_path)
	return _ok({"scripts": scripts})


func _get_editor_screenshot(_params: Dictionary) -> Dictionary:
	return await _request_screenshot("editor")


func _get_game_screenshot(_params: Dictionary) -> Dictionary:
	return await _request_screenshot("game")


func _reload_plugin(_params: Dictionary) -> Dictionary:
	editor_plugin.get_editor_interface().set_plugin_enabled("res://addons/godot_mcp/plugin.cfg", false)
	editor_plugin.get_editor_interface().set_plugin_enabled("res://addons/godot_mcp/plugin.cfg", true)
	return _ok({"reloaded": true})


func _reload_project(_params: Dictionary) -> Dictionary:
	editor_plugin.get_editor_interface().get_resource_filesystem().scan()
	editor_plugin.get_editor_interface().reload_scene_from_path(
		_edited_root().scene_file_path if _edited_root() else ""
	)
	return _ok({"reloaded": true})


func _get_editor_camera(_params: Dictionary) -> Dictionary:
	var ei := editor_plugin.get_editor_interface()
	var cameras: Array = []
	var count := 1
	if ei.has_method("get_editor_viewport_3d_count"):
		count = ei.get_editor_viewport_3d_count()
	for i in count:
		if not ei.has_method("get_editor_viewport_3d"):
			break
		var vp = ei.get_editor_viewport_3d(i)
		if vp == null:
			continue
		var xform: Transform3D = vp.get_camera_transform()
		cameras.append({
			"viewport_index": i,
			"position": {"x": xform.origin.x, "y": xform.origin.y, "z": xform.origin.z},
			"rotation": {"x": xform.basis.get_euler().x, "y": xform.basis.get_euler().y, "z": xform.basis.get_euler().z},
		})
	return _ok({"cameras": cameras, "count": cameras.size()})


func _set_editor_camera(params: Dictionary) -> Dictionary:
	var ei := editor_plugin.get_editor_interface()
	if not ei.has_method("get_editor_viewport_3d"):
		return _err("3D editor viewport not available")
	var idx: int = int(params.get("viewport_index", 0))
	var vp = ei.get_editor_viewport_3d(idx)
	if vp == null:
		return _err("Viewport not found: %d" % idx)
	var pos_dict: Variant = params.get("position", {})
	var pos := Vector3(
		float(params.get("x", pos_dict.x if pos_dict is Vector3 else (pos_dict.get("x", 0) if pos_dict is Dictionary else 0))),
		float(params.get("y", pos_dict.y if pos_dict is Vector3 else (pos_dict.get("y", 0) if pos_dict is Dictionary else 0))),
		float(params.get("z", pos_dict.z if pos_dict is Vector3 else (pos_dict.get("z", 0) if pos_dict is Dictionary else 0)))
	)
	var rot_dict: Variant = params.get("rotation", {})
	var rot := Vector3(
		float(params.get("rotation_x", rot_dict.x if rot_dict is Vector3 else (rot_dict.get("x", 0) if rot_dict is Dictionary else 0))),
		float(params.get("rotation_y", rot_dict.y if rot_dict is Vector3 else (rot_dict.get("y", 0) if rot_dict is Dictionary else 0))),
		float(params.get("rotation_z", rot_dict.z if rot_dict is Vector3 else (rot_dict.get("z", 0) if rot_dict is Dictionary else 0)))
	)
	var xform := Transform3D(Basis.from_euler(rot), pos)
	vp.set_camera_transform(xform)
	return _ok({"viewport_index": idx, "position": _serialize_value(pos), "rotation": _serialize_value(rot)})


func _set_auto_dismiss(params: Dictionary) -> Dictionary:
	if "auto_dismiss_dialogs" in editor_plugin:
		editor_plugin.auto_dismiss_dialogs = params.get("enabled", true)
		return _ok({"auto_dismiss_dialogs": editor_plugin.auto_dismiss_dialogs})
	return _err("Plugin does not support auto dismiss")


func _compare_screenshots(p: Dictionary) -> Dictionary:
	var path_a: String = p.get("path_a", "")
	var path_b: String = p.get("path_b", "")
	var img_a := Image.load_from_file(path_a)
	var img_b := Image.load_from_file(path_b)
	if img_a == null or img_b == null:
		return _err("Failed to load images")
	if img_a.get_size() != img_b.get_size():
		return _ok({"match": false, "reason": "size_mismatch", "size_a": str(img_a.get_size()), "size_b": str(img_b.get_size())})
	var diff := 0
	var pixels := img_a.get_width() * img_a.get_height()
	for y in img_a.get_height():
		for x in img_a.get_width():
			if img_a.get_pixel(x, y) != img_b.get_pixel(x, y):
				diff += 1
	var ratio := float(diff) / float(maxi(pixels, 1))
	return _ok({"match": diff == 0, "diff_pixels": diff, "total_pixels": pixels, "diff_ratio": ratio})
