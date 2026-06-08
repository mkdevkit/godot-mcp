@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"


func get_commands() -> Dictionary:
	return {
		"get_project_info": _get_project_info,
		"search_files": _search_files,
		"get_filesystem_tree": _get_filesystem_tree,
		"get_project_settings": _get_project_settings,
		"set_project_setting": _set_project_setting,
		"uid_to_project_path": _uid_to_project_path,
		"project_path_to_uid": _project_path_to_uid,
	}


func _get_project_info(_params: Dictionary) -> Dictionary:
	var autoloads := {}
	for setting in ProjectSettings.get_setting("autoload", {}):
		autoloads[setting] = ProjectSettings.get_setting("autoload/%s" % setting)

	return _ok({
		"name": ProjectSettings.get_setting("application/config/name", "Untitled"),
		"description": ProjectSettings.get_setting("application/config/description", ""),
		"godot_version": Engine.get_version_info(),
		"project_path": ProjectSettings.globalize_path("res://"),
		"main_scene": str(ProjectSettings.get_setting("application/run/main_scene", "")),
		"features": ProjectSettings.get_setting("application/config/features", PackedStringArray()),
		"autoloads": autoloads,
		"current_scene": editor_plugin.get_editor_interface().get_edited_scene_root().scene_file_path if _edited_root() else "",
	})


func _search_files(params: Dictionary) -> Dictionary:
	var pattern: String = params.get("pattern", "*")
	var directory: String = params.get("directory", "res://")
	var recursive: bool = params.get("recursive", true)
	var max_results: int = int(params.get("max_results", 100))

	if not directory.begins_with("res://"):
		directory = "res://" + directory.trim_prefix("/")

	var results: Array = []
	_collect_files(directory, pattern, recursive, results, max_results)
	return _ok({"files": results, "count": results.size()})


func _collect_files(path: String, pattern: String, recursive: bool, results: Array, max_results: int) -> void:
	if results.size() >= max_results:
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path := path.path_join(file_name)
		if dir.current_is_dir():
			if recursive:
				_collect_files(full_path, pattern, recursive, results, max_results)
		elif _match_pattern(file_name, pattern):
			results.append(full_path)
			if results.size() >= max_results:
				break
		file_name = dir.get_next()
	dir.list_dir_end()


func _escape_glob_pattern(pattern: String) -> String:
	var escaped := ""
	for i in pattern.length():
		var ch := pattern[i]
		if ch == "*":
			escaped += ".*"
		elif ch in "\\.^$+?{}[]|()":
			escaped += "\\" + ch
		else:
			escaped += ch
	return escaped


func _match_pattern(file_name: String, pattern: String) -> bool:
	if pattern == "*" or pattern.is_empty():
		return true
	if pattern.contains("*"):
		var regex := RegEx.new()
		var escaped := _escape_glob_pattern(pattern)
		regex.compile("^%s$" % escaped)
		return regex.search(file_name) != null
	return file_name.contains(pattern)


func _get_filesystem_tree(params: Dictionary) -> Dictionary:
	var directory: String = params.get("directory", "res://")
	var max_depth: int = int(params.get("max_depth", 4))
	if not directory.begins_with("res://"):
		directory = "res://" + directory.trim_prefix("/")
	return _ok({"tree": _build_tree(directory, 0, max_depth)})


func _build_tree(path: String, depth: int, max_depth: int) -> Dictionary:
	var node := {"path": path, "type": "directory", "children": []}
	if depth >= max_depth:
		return node
	var dir := DirAccess.open(path)
	if dir == null:
		return node
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path := path.path_join(file_name)
		if dir.current_is_dir():
			node["children"].append(_build_tree(full_path, depth + 1, max_depth))
		else:
			node["children"].append({"path": full_path, "type": "file"})
		file_name = dir.get_next()
	dir.list_dir_end()
	return node


func _get_project_settings(params: Dictionary) -> Dictionary:
	var keys: Array = params.get("keys", [])
	var result := {}
	if keys.is_empty():
		for section in ["application", "display", "rendering", "input", "layer_names"]:
			result[section] = {}
	else:
		for key in keys:
			if ProjectSettings.has_setting(key):
				result[key] = _serialize_value(ProjectSettings.get_setting(key))
	return _ok({"settings": result})


func _set_project_setting(params: Dictionary) -> Dictionary:
	var key: String = params.get("key", "")
	var value_text: String = str(params.get("value", ""))
	if key.is_empty():
		return _err("Missing 'key' parameter")

	var parsed: Variant = TypeParser.parse(value_text)
	ProjectSettings.set_setting(key, parsed)
	ProjectSettings.save()
	return _ok({"key": key, "value": _serialize_value(parsed)})


func _uid_to_project_path(params: Dictionary) -> Dictionary:
	var uid_text: String = params.get("uid", "")
	var path := ResourceUtils.path_for_uid(uid_text)
	if path.is_empty():
		return _err("Invalid or unknown UID: %s" % uid_text)
	return _ok({"uid": uid_text, "path": path})


func _project_path_to_uid(params: Dictionary) -> Dictionary:
	var path := _norm_res(params.get("path", ""))
	var uid := ResourceUtils.uid_for_path(path)
	if uid.is_empty():
		return _err("No UID for path: %s" % path)
	return _ok({"path": path, "uid": uid})
