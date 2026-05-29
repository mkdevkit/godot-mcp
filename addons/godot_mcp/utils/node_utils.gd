@tool
extends RefCounted
class_name MCPNodeUtils

static func normalize_path(path: String) -> String:
	if path.is_empty():
		return "."
	if path.begins_with("res://") or path.begins_with("/root"):
		return path
	if path.begins_with("/"):
		return path.substr(1)
	return path


static func resolve_in_tree(root: Node, path: String) -> Node:
	if root == null:
		return null
	var p := normalize_path(path)
	if p == ".":
		return root
	return root.get_node_or_null(NodePath(p))


static func collect_by_type(root: Node, type_name: String, results: Array, max_count: int = 500) -> void:
	if results.size() >= max_count or root == null:
		return
	if root.get_class() == type_name or root.is_class(type_name):
		results.append({"path": str(root.get_path()), "name": root.name, "type": root.get_class()})
	for child in root.get_children():
		collect_by_type(child, type_name, results, max_count)


static func collect_in_group(root: Node, group: String, results: Array) -> void:
	if root == null:
		return
	if root.is_in_group(group):
		results.append({"path": str(root.get_path()), "name": root.name, "type": root.get_class()})
	for child in root.get_children():
		collect_in_group(child, group, results)


static func find_by_script(root: Node, script_path: String, results: Array) -> void:
	if root == null:
		return
	var script: Script = root.get_script()
	if script and script.resource_path == script_path:
		results.append({"path": str(root.get_path()), "name": root.name})
	for child in root.get_children():
		find_by_script(child, script_path, results)


static func tree_dict(node: Node, depth: int = 0, max_depth: int = 10) -> Dictionary:
	var info := {"name": node.name, "type": node.get_class(), "path": str(node.get_path())}
	if depth < max_depth:
		var children: Array = []
		for child in node.get_children():
			children.append(tree_dict(child, depth + 1, max_depth))
		info["children"] = children
	return info
