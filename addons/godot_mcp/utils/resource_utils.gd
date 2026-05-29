@tool
extends RefCounted
class_name MCPResourceUtils

static func normalize_res(path: String) -> String:
	if path.is_empty():
		return path
	if path.begins_with("res://"):
		return path
	return "res://" + path.trim_prefix("/")


static func read_text(path: String) -> String:
	var p := normalize_res(path)
	if not FileAccess.file_exists(p):
		return ""
	return FileAccess.get_file_as_string(p)


static func write_text(path: String, content: String) -> Error:
	var p := normalize_res(path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p.get_base_dir()))
	var file := FileAccess.open(p, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_CREATE
	file.store_string(content)
	file.close()
	return OK


static func parse_tres_properties(path: String) -> Dictionary:
	var content := read_text(path)
	var props := {}
	for line in content.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("[") or trimmed.begins_with(";"):
			continue
		if "=" in trimmed:
			var parts := trimmed.split("=", true, 1)
			props[parts[0].strip_edges()] = parts[1].strip_edges()
	return props


static func uid_for_path(path: String) -> String:
	var p := normalize_res(path)
	if ResourceLoader.exists(p):
		return ResourceUID.id_to_text(ResourceLoader.get_resource_uid(p))
	return ""


static func path_for_uid(uid_text: String) -> String:
	var id := ResourceUID.text_to_id(uid_text)
	if id == ResourceUID.INVALID_ID:
		return ""
	return ResourceUID.get_id_path(id)
