@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"find_nodes_by_type": _find_nodes_by_type,
		"find_signal_connections": _find_signal_connections,
		"batch_set_property": _batch_set_property,
		"find_node_references": _find_node_references,
		"get_scene_dependencies": _get_scene_dependencies,
		"cross_scene_set_property": _cross_scene_set_property,
		"find_script_references": _find_script_references,
		"detect_circular_dependencies": _detect_circular_dependencies,
		"batch_add_nodes": _batch_add_nodes,
	}


func _find_nodes_by_type(p: Dictionary) -> Dictionary:
	var type_name: String = p.get("type", "Node")
	var results: Array = []
	NodeUtils.collect_by_type(_edited_root(), type_name, results)
	return _ok({"type": type_name, "nodes": results})


func _find_signal_connections(_p: Dictionary) -> Dictionary:
	var root := _edited_root()
	if root == null:
		return _err("No scene open")
	var connections: Array = []
	_collect_signals(root, connections)
	return _ok({"connections": connections})


func _collect_signals(node: Node, out: Array) -> void:
	for sig in node.get_signal_list():
		for conn in node.get_signal_connection_list(sig.name):
			out.append({
				"from": str(node.get_path()),
				"signal": sig.name,
				"to": str(conn.callable.get_object()),
				"method": conn.callable.get_method(),
			})
	for child in node.get_children():
		_collect_signals(child, out)


func _batch_set_property(p: Dictionary) -> Dictionary:
	var type_name: String = p.get("type", "")
	var property: String = p.get("property", "")
	var value = _parse_value(str(p.get("value", "")))
	var results: Array = []
	NodeUtils.collect_by_type(_edited_root(), type_name, results)
	var count := 0
	for item in results:
		var node := _resolve_node(item["path"])
		if node:
			_undo_property(node, property, value)
			count += 1
	return _ok({"updated": count})


func _find_node_references(p: Dictionary) -> Dictionary:
	var pattern: String = p.get("pattern", "")
	var matches: Array = []
	_search_in_dir("res://", pattern, matches)
	return _ok({"matches": matches})


func _search_in_dir(path: String, pattern: String, matches: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.begins_with("."):
			f = dir.get_next()
			continue
		var full := path.path_join(f)
		if dir.current_is_dir():
			_search_in_dir(full, pattern, matches)
		elif f.ends_with(".tscn") or f.ends_with(".gd"):
			var content := FileAccess.get_file_as_string(full)
			if content.contains(pattern):
				matches.append(full)
		f = dir.get_next()
	dir.list_dir_end()


func _get_scene_dependencies(p: Dictionary) -> Dictionary:
	var scene_path := _norm_res(p.get("scene_path", ""))
	if scene_path.is_empty() and _edited_root():
		scene_path = _edited_root().scene_file_path
	var deps: Array = []
	if ResourceLoader.exists(scene_path):
		var state := ResourceLoader.load(scene_path)
		if state is PackedScene:
			for ext in ResourceLoader.get_dependencies(scene_path):
				deps.append(ext)
	return _ok({"scene": scene_path, "dependencies": deps})


func _cross_scene_set_property(p: Dictionary) -> Dictionary:
	var directory := _norm_res(p.get("directory", "res://"))
	var property: String = p.get("property", "")
	var value_text: String = str(p.get("value", ""))
	var type_name: String = p.get("type", "")
	var updated: Array = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return _err("Invalid directory")
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".tscn"):
			var path := directory.path_join(f)
			var packed: PackedScene = load(path)
			if packed:
				var inst := packed.instantiate()
				_set_on_matching(inst, type_name, property, value_text, updated, path)
				inst.free()
		f = dir.get_next()
	dir.list_dir_end()
	return _ok({"updated_scenes": updated})


func _set_on_matching(node: Node, type_name: String, property: String, value_text: String, updated: Array, scene_path: String) -> void:
	if node.get_class() == type_name or node.is_class(type_name):
		node.set(property, _parse_value(value_text))
		if scene_path not in updated:
			updated.append(scene_path)
	for child in node.get_children():
		_set_on_matching(child, type_name, property, value_text, updated, scene_path)


func _find_script_references(p: Dictionary) -> Dictionary:
	var script_path := _norm_res(p.get("script_path", ""))
	var matches: Array = []
	_search_in_dir("res://", script_path, matches)
	return _ok({"script": script_path, "references": matches})


func _detect_circular_dependencies(p: Dictionary) -> Dictionary:
	var scene_path := _norm_res(p.get("scene_path", ""))
	var visited := {}
	var stack := {}
	var cycles: Array = []
	_detect_cycle(scene_path, visited, stack, cycles, [])
	return _ok({"cycles": cycles})


func _batch_add_nodes(p: Dictionary) -> Dictionary:
	var nodes_data: Array = p.get("nodes", [])
	if nodes_data.is_empty():
		return _err("Missing non-empty 'nodes' array")
	var root := _edited_root()
	if root == null:
		return _err("No scene open")
	var created: Array = []
	var errors: Array = []
	for i in nodes_data.size():
		var entry: Dictionary = nodes_data[i]
		var node_type: String = entry.get("type", "")
		if node_type.is_empty() or not ClassDB.class_exists(node_type):
			errors.append({"index": i, "error": "Invalid type: %s" % node_type})
			continue
		var parent := _resolve_node(str(entry.get("parent_path", ".")))
		if parent == null:
			errors.append({"index": i, "error": "Parent not found"})
			continue
		var node: Node = ClassDB.instantiate(node_type)
		if entry.has("name"):
			node.name = str(entry["name"])
		editor_plugin.get_undo_redo().create_action("MCP Batch Add Node")
		editor_plugin.get_undo_redo().add_do_method(parent, "add_child", node, true)
		editor_plugin.get_undo_redo().add_do_method(node, "set_owner", root)
		editor_plugin.get_undo_redo().add_undo_method(parent, "remove_child", node)
		editor_plugin.get_undo_redo().commit_action()
		for key in entry.get("properties", {}):
			node.set(str(key), _parse_value(str(entry["properties"][key])))
		created.append({"index": i, "path": str(node.get_path()), "type": node_type})
	return _ok({"created": created, "count": created.size(), "errors": errors})


func _detect_cycle(path: String, visited: Dictionary, stack: Dictionary, cycles: Array, chain: Array) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	if stack.has(path):
		cycles.append(chain + [path])
		return
	if visited.has(path):
		return
	visited[path] = true
	stack[path] = true
	var next_chain := chain + [path]
	for dep in ResourceLoader.get_dependencies(path):
		if dep.ends_with(".tscn"):
			_detect_cycle(dep, visited, stack, cycles, next_chain)
	stack.erase(path)
