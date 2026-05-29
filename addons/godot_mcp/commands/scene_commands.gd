@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"


func get_commands() -> Dictionary:
	return {
		"get_scene_tree": _get_scene_tree,
		"get_scene_file_content": _get_scene_file_content,
		"open_scene": _open_scene,
		"save_scene": _save_scene,
		"create_scene": _create_scene,
		"play_scene": _play_scene,
		"stop_scene": _stop_scene,
		"delete_scene": _delete_scene,
		"add_scene_instance": _add_scene_instance,
		"get_scene_exports": _get_scene_exports,
	}


func _get_scene_tree(_params: Dictionary) -> Dictionary:
	var root := _edited_root()
	if root == null:
		return _ok({"scene": null, "message": "No scene is currently open"})
	return _ok({
		"scene_path": root.scene_file_path,
		"root": _node_to_dict(root),
	})


func _get_scene_file_content(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("scene_path", "")
	if scene_path.is_empty():
		var root := _edited_root()
		if root == null:
			return _err("No scene open and no scene_path provided")
		scene_path = root.scene_file_path
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path.trim_prefix("/")
	if not FileAccess.file_exists(scene_path):
		return _err("Scene file not found: %s" % scene_path, -32001)
	return _ok({"scene_path": scene_path, "content": FileAccess.get_file_as_string(scene_path)})


func _open_scene(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("scene_path", "")
	if scene_path.is_empty():
		return _err("Missing 'scene_path'")
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path.trim_prefix("/")
	if not FileAccess.file_exists(scene_path):
		return _err("Scene file not found: %s" % scene_path, -32001)
	editor_plugin.get_editor_interface().open_scene_from_path(scene_path)
	return _ok({"scene_path": scene_path, "opened": true})


func _save_scene(_params: Dictionary) -> Dictionary:
	var root := _edited_root()
	if root == null:
		return _err("No scene is open")
	var path := root.scene_file_path
	if path.is_empty():
		return _err("Scene has no file path — save manually first or use create_scene")
	editor_plugin.get_editor_interface().save_scene()
	return _ok({"scene_path": path, "saved": true})


func _create_scene(params: Dictionary) -> Dictionary:
	var scene_path: String = params.get("scene_path", "")
	var root_type: String = params.get("root_type", "Node2D")
	if scene_path.is_empty():
		return _err("Missing 'scene_path'")
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path.trim_prefix("/")
	if FileAccess.file_exists(scene_path) and not params.get("overwrite", false):
		return _err("Scene already exists: %s" % scene_path, -32002, {"suggestion": "Set overwrite=true to replace"})

	if not ClassDB.class_exists(root_type):
		return _err("Unknown node type: %s" % root_type)

	var root: Node = ClassDB.instantiate(root_type)
	root.name = scene_path.get_file().get_basename()
	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, scene_path)
	root.free()
	if err != OK:
		return _err("Failed to create scene: error %d" % err)
	editor_plugin.get_editor_interface().open_scene_from_path(scene_path)
	return _ok({"scene_path": scene_path, "root_type": root_type, "created": true})


func _play_scene(params: Dictionary) -> Dictionary:
	var mode: String = params.get("mode", "current")
	match mode:
		"main":
			editor_plugin.get_editor_interface().play_main_scene()
		"current":
			editor_plugin.get_editor_interface().play_current_scene()
		_:
			var scene_path: String = params.get("scene_path", "")
			if scene_path.is_empty():
				return _err("Custom play mode requires scene_path")
			if not scene_path.begins_with("res://"):
				scene_path = "res://" + scene_path.trim_prefix("/")
			editor_plugin.get_editor_interface().play_custom_scene(scene_path)
	return _ok({"playing": true, "mode": mode})


func _stop_scene(_params: Dictionary) -> Dictionary:
	editor_plugin.get_editor_interface().stop_playing_scene()
	return _ok({"playing": false})


func _delete_scene(params: Dictionary) -> Dictionary:
	var scene_path := _norm_res(params.get("scene_path", ""))
	if scene_path.is_empty():
		return _err("Missing scene_path")
	if not FileAccess.file_exists(scene_path):
		return _err("Scene not found: %s" % scene_path)
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(scene_path))
	if err != OK:
		return _err("Failed to delete scene")
	editor_plugin.get_editor_interface().get_resource_filesystem().scan()
	return _ok({"deleted": scene_path})


func _add_scene_instance(params: Dictionary) -> Dictionary:
	var scene_path := _norm_res(params.get("scene_path", ""))
	var parent_path: String = params.get("parent_path", ".")
	var instance_name: String = params.get("name", "")
	if scene_path.is_empty():
		return _err("Missing scene_path")
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return _err("Failed to load scene: %s" % scene_path)
	var parent := _resolve_node(parent_path)
	if parent == null:
		return _err("Parent not found")
	var inst := packed.instantiate()
	if not instance_name.is_empty():
		inst.name = instance_name
	var root := _edited_root()
	editor_plugin.get_undo_redo().create_action("MCP Instance Scene")
	editor_plugin.get_undo_redo().add_do_method(parent, "add_child", inst, true)
	editor_plugin.get_undo_redo().add_do_method(inst, "set_owner", root)
	editor_plugin.get_undo_redo().add_undo_method(parent, "remove_child", inst)
	editor_plugin.get_undo_redo().commit_action()
	return _ok({"path": str(inst.get_path()), "scene": scene_path})


func _get_scene_exports(p: Dictionary) -> Dictionary:
	var path := _norm_res(p.get("path", p.get("scene_path", "")))
	if path.is_empty() and _edited_root():
		path = _edited_root().scene_file_path
	if path.is_empty():
		return _err("Missing scene path")
	if not FileAccess.file_exists(path):
		return _err("Scene not found: %s" % path)
	var packed: PackedScene = load(path)
	if packed == null:
		return _err("Failed to load scene")
	var instance := packed.instantiate()
	var nodes_data: Array = []
	_collect_exports(instance, instance, nodes_data)
	instance.free()
	return _ok({"path": path, "nodes": nodes_data, "count": nodes_data.size()})


func _collect_exports(node: Node, root: Node, out: Array) -> void:
	var script: Script = node.get_script()
	if script:
		var exports := {}
		for info in script.get_script_property_list():
			if (info.usage & PROPERTY_USAGE_EDITOR) and (info.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
				exports[info.name] = _serialize_value(node.get(info.name))
		if not exports.is_empty():
			out.append({
				"node_path": "." if node == root else str(root.get_path_to(node)),
				"node_name": node.name,
				"node_type": node.get_class(),
				"script_path": script.resource_path,
				"exports": exports,
			})
	for child in node.get_children():
		_collect_exports(child, root, out)
