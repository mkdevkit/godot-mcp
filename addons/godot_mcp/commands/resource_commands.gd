@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"read_resource": _read_resource,
		"edit_resource": _edit_resource,
		"create_resource": _create_resource,
		"get_resource_preview": _get_resource_preview,
		"add_autoload": _add_autoload,
		"remove_autoload": _remove_autoload,
	}


func _read_resource(p: Dictionary) -> Dictionary:
	var path := _norm_res(p.get("resource_path", ""))
	if not ResourceLoader.exists(path):
		return _err("Resource not found")
	var res: Resource = load(path)
	var props := {}
	if res:
		for info in res.get_property_list():
			if info.usage & PROPERTY_USAGE_EDITOR:
				props[info.name] = _serialize_value(res.get(info.name))
	return _ok({"path": path, "type": res.get_class() if res else "", "properties": props})


func _edit_resource(p: Dictionary) -> Dictionary:
	var path := _norm_res(p.get("resource_path", ""))
	var res: Resource = load(path)
	if res == null:
		return _err("Resource not found")
	for key in p.get("properties", {}):
		res.set(str(key), _parse_value(str(p["properties"][key])))
	ResourceSaver.save(res, path)
	return _ok({"updated": path})


func _create_resource(p: Dictionary) -> Dictionary:
	var path := _norm_res(p.get("resource_path", ""))
	var type_name: String = p.get("type", "Resource")
	if not ClassDB.class_exists(type_name):
		return _err("Unknown type")
	var res: Resource = ClassDB.instantiate(type_name)
	ResourceSaver.save(res, path)
	return _ok({"created": path})


func _get_resource_preview(p: Dictionary) -> Dictionary:
	var path := _norm_res(p.get("resource_path", ""))
	var tex: Texture2D = editor_plugin.get_editor_interface().get_resource_filesystem().get_file_icon(path)
	return _ok({"path": path, "has_icon": tex != null})


func _add_autoload(p: Dictionary) -> Dictionary:
	var name: String = p.get("name", "")
	var script_path := _norm_res(p.get("script_path", ""))
	if name.is_empty():
		return _err("Missing name")
	ProjectSettings.set_setting("autoload/%s" % name, "*%s" % script_path)
	ProjectSettings.save()
	return _ok({"autoload": name, "path": script_path})


func _remove_autoload(p: Dictionary) -> Dictionary:
	var name: String = p.get("name", "")
	ProjectSettings.set_setting("autoload/%s" % name, null)
	ProjectSettings.save()
	return _ok({"removed": name})
