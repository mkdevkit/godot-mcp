@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"


func get_commands() -> Dictionary:
	return {
		"list_scripts": _list_scripts,
		"read_script": _read_script,
		"create_script": _create_script,
		"edit_script": _edit_script,
		"attach_script": _attach_script,
		"validate_script": _validate_script,
		"search_in_files": _search_in_files,
	}


func _list_scripts(_params: Dictionary) -> Dictionary:
	var scripts: Array = []
	_collect_scripts("res://", scripts)
	return _ok({"scripts": scripts, "count": scripts.size()})


func _collect_scripts(path: String, results: Array) -> void:
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
			_collect_scripts(full_path, results)
		elif file_name.ends_with(".gd"):
			var info := {"path": full_path}
			var script := load(full_path)
			if script is GDScript:
				info["class_name"] = script.get_global_name()
			results.append(info)
		file_name = dir.get_next()
	dir.list_dir_end()


func _read_script(params: Dictionary) -> Dictionary:
	var script_path: String = params.get("script_path", "")
	if script_path.is_empty():
		return _err("Missing 'script_path'")
	if not script_path.begins_with("res://"):
		script_path = "res://" + script_path.trim_prefix("/")
	if not FileAccess.file_exists(script_path):
		return _err("Script not found: %s" % script_path)
	return _ok({"script_path": script_path, "content": FileAccess.get_file_as_string(script_path)})


func _create_script(params: Dictionary) -> Dictionary:
	var script_path: String = params.get("script_path", "")
	var content: String = params.get("content", "extends Node\n")
	var overwrite: bool = params.get("overwrite", false)
	if script_path.is_empty():
		return _err("Missing 'script_path'")
	if not script_path.begins_with("res://"):
		script_path = "res://" + script_path.trim_prefix("/")
	if FileAccess.file_exists(script_path) and not overwrite:
		return _err("Script already exists: %s" % script_path, -32002)

	var dir_path := script_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		return _err("Failed to write script: %s" % script_path)
	file.store_string(content)
	file.close()
	editor_plugin.get_editor_interface().get_resource_filesystem().scan()
	return _ok({"script_path": script_path, "created": true})


func _edit_script(params: Dictionary) -> Dictionary:
	var script_path: String = params.get("script_path", "")
	var content: String = params.get("content", "")
	var search: String = params.get("search", "")
	var replace: String = params.get("replace", "")
	if script_path.is_empty():
		return _err("Missing 'script_path'")
	if not script_path.begins_with("res://"):
		script_path = "res://" + script_path.trim_prefix("/")
	if not FileAccess.file_exists(script_path):
		return _err("Script not found: %s" % script_path)

	var existing := FileAccess.get_file_as_string(script_path)
	if not content.is_empty():
		existing = content
	elif not search.is_empty():
		if not existing.contains(search):
			return _err("Search text not found in script")
		existing = existing.replace(search, replace)

	var file := FileAccess.open(script_path, FileAccess.WRITE)
	file.store_string(existing)
	file.close()
	editor_plugin.get_editor_interface().get_resource_filesystem().scan()
	return _ok({"script_path": script_path, "updated": true})


func _attach_script(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var script_path: String = params.get("script_path", "")
	var node := _resolve_node(node_path)
	if node == null:
		return _err("Node not found: %s" % node_path)
	if script_path.is_empty():
		return _err("Missing 'script_path'")
	if not script_path.begins_with("res://"):
		script_path = "res://" + script_path.trim_prefix("/")
	if not FileAccess.file_exists(script_path):
		return _err("Script not found: %s" % script_path)

	var script: Script = load(script_path)
	if script == null:
		return _err("Failed to load script: %s" % script_path)

	editor_plugin.get_undo_redo().create_action("MCP Attach Script")
	editor_plugin.get_undo_redo().add_do_method(node, "set_script", script)
	editor_plugin.get_undo_redo().add_undo_method(node, "set_script", node.get_script())
	editor_plugin.get_undo_redo().commit_action()

	return _ok({"node_path": str(node.get_path()), "script_path": script_path})


func _validate_script(params: Dictionary) -> Dictionary:
	var script_path: String = params.get("script_path", "")
	var content: String = params.get("content", "")
	if script_path.is_empty() and content.is_empty():
		return _err("Provide script_path or content")

	if content.is_empty():
		if not script_path.begins_with("res://"):
			script_path = "res://" + script_path.trim_prefix("/")
		content = FileAccess.get_file_as_string(script_path)

	var script := GDScript.new()
	script.set_source_code(content)
	var err: Error = script.reload()
	if err != OK:
		return _ok({"valid": false, "error": "Syntax error (code %d)" % err})
	return _ok({"valid": true})


func _search_in_files(params: Dictionary) -> Dictionary:
	var query: String = params.get("query", "")
	var directory: String = params.get("directory", "res://")
	var max_results: int = int(params.get("max_results", 50))
	if query.is_empty():
		return _err("Missing 'query'")

	var matches: Array = []
	_search_content(directory, query, matches, max_results)
	return _ok({"matches": matches, "count": matches.size()})


func _search_content(path: String, query: String, matches: Array, max_results: int) -> void:
	if matches.size() >= max_results:
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
			_search_content(full_path, query, matches, max_results)
		elif file_name.ends_with(".gd") or file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
			var content := FileAccess.get_file_as_string(full_path)
			if content.contains(query):
				var line_num := 0
				for line in content.split("\n"):
					line_num += 1
					if line.contains(query):
						matches.append({"file": full_path, "line": line_num, "text": line.strip_edges()})
						if matches.size() >= max_results:
							break
		file_name = dir.get_next()
	dir.list_dir_end()
