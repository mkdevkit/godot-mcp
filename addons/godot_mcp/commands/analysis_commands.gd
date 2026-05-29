@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"analyze_scene_complexity": _analyze_scene_complexity,
		"analyze_signal_flow": _analyze_signal_flow,
		"find_unused_resources": _find_unused_resources,
		"get_project_statistics": _get_project_statistics,
	}


func _analyze_scene_complexity(_p: Dictionary) -> Dictionary:
	var root := _edited_root()
	if root == null:
		return _err("No scene open")
	var stats := {"nodes": 0, "max_depth": 0, "types": {}}
	_walk_complexity(root, 0, stats)
	return _ok(stats)


func _walk_complexity(node: Node, depth: int, stats: Dictionary) -> void:
	stats["nodes"] = int(stats["nodes"]) + 1
	stats["max_depth"] = maxi(int(stats["max_depth"]), depth)
	var t: String = node.get_class()
	stats["types"][t] = int(stats["types"].get(t, 0)) + 1
	for child in node.get_children():
		_walk_complexity(child, depth + 1, stats)


func _analyze_signal_flow(_p: Dictionary) -> Dictionary:
	var connections: Array = []
	if _edited_root():
		_collect_all_signals(_edited_root(), connections)
	return _ok({"signal_count": connections.size(), "connections": connections})


func _collect_all_signals(node: Node, out: Array) -> void:
	for sig in node.get_signal_list():
		for conn in node.get_signal_connection_list(sig.name):
			out.append({"from": str(node.get_path()), "signal": sig.name, "to": str(conn.callable.get_object())})
	for child in node.get_children():
		_collect_all_signals(child, out)


func _find_unused_resources(p: Dictionary) -> Dictionary:
	var directory := _norm_res(p.get("directory", "res://"))
	var all_files: Array = []
	var referenced := {}
	_collect_files_flat(directory, all_files)
	_scan_references("res://", referenced)
	var unused: Array = []
	for f in all_files:
		if f not in referenced and not str(f).ends_with(".import"):
			unused.append(f)
	return _ok({"unused": unused.slice(0, int(p.get("max_results", 100)))})


func _collect_files_flat(path: String, out: Array) -> void:
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
			_collect_files_flat(full, out)
		else:
			out.append(full)
		f = dir.get_next()
	dir.list_dir_end()


func _scan_references(path: String, referenced: Dictionary) -> void:
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
			_scan_references(full, referenced)
		elif f.ends_with(".tscn") or f.ends_with(".gd") or f.ends_with(".tres"):
			var content := FileAccess.get_file_as_string(full)
			for m in content.split("res://"):
				if m.contains("\""):
					var ref := "res://" + m.split("\"")[0]
					referenced[ref] = true
		f = dir.get_next()
	dir.list_dir_end()


func _get_project_statistics(_p: Dictionary) -> Dictionary:
	var counts := {"scripts": 0, "scenes": 0, "resources": 0}
	_count_types("res://", counts)
	return _ok({
		"scripts": counts.scripts,
		"scenes": counts.scenes,
		"resources": counts.resources,
		"godot_version": Engine.get_version_info(),
	})


func _count_types(path: String, counts: Dictionary) -> void:
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
			_count_types(full, counts)
		elif f.ends_with(".gd"):
			counts.scripts = int(counts.scripts) + 1
		elif f.ends_with(".tscn"):
			counts.scenes = int(counts.scenes) + 1
		elif f.ends_with(".tres"):
			counts.resources = int(counts.resources) + 1
		f = dir.get_next()
	dir.list_dir_end()
