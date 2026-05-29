@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

const TypeParser = preload("res://addons/godot_mcp/utils/type_parser.gd")


func get_commands() -> Dictionary:
	return {
		"add_node": _add_node,
		"delete_node": _delete_node,
		"duplicate_node": _duplicate_node,
		"move_node": _move_node,
		"rename_node": _rename_node,
		"update_property": _update_property,
		"get_node_properties": _get_node_properties,
		"get_signals": _get_signals,
		"add_resource": _add_resource,
		"set_anchor_preset": _set_anchor_preset,
		"connect_signal": _connect_signal,
		"disconnect_signal": _disconnect_signal,
		"get_node_groups": _get_node_groups,
		"set_node_groups": _set_node_groups,
		"find_nodes_in_group": _find_nodes_in_group,
	}


func _add_node(params: Dictionary) -> Dictionary:
	var node_type: String = params.get("type", "Node")
	var node_name: String = params.get("name", "")
	var parent_path: String = params.get("parent_path", ".")
	var properties: Dictionary = params.get("properties", {})

	if not ClassDB.class_exists(node_type):
		return _err("Unknown node type: %s" % node_type)

	var root := _edited_root()
	if root == null:
		return _err("No scene is open")

	var parent := _resolve_node(parent_path)
	if parent == null:
		return _err("Parent node not found: %s" % parent_path)

	var node: Node = ClassDB.instantiate(node_type)
	if not node_name.is_empty():
		node.name = node_name

	editor_plugin.get_undo_redo().create_action("MCP Add Node")
	editor_plugin.get_undo_redo().add_do_method(parent, "add_child", node, true)
	editor_plugin.get_undo_redo().add_do_method(node, "set_owner", root)
	editor_plugin.get_undo_redo().add_undo_method(parent, "remove_child", node)
	editor_plugin.get_undo_redo().commit_action()

	for key in properties:
		node.set(key, TypeParser.parse(str(properties[key])))

	return _ok({
		"path": str(node.get_path()),
		"type": node_type,
		"name": node.name,
	})


func _delete_node(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var node := _resolve_node(node_path)
	if node == null:
		return _err("Node not found: %s" % node_path)
	if node == _edited_root():
		return _err("Cannot delete scene root")

	var parent := node.get_parent()
	editor_plugin.get_undo_redo().create_action("MCP Delete Node")
	editor_plugin.get_undo_redo().add_do_method(parent, "remove_child", node)
	editor_plugin.get_undo_redo().add_undo_method(parent, "add_child", node, true)
	editor_plugin.get_undo_redo().add_undo_method(node, "set_owner", _edited_root())
	editor_plugin.get_undo_redo().commit_action()

	return _ok({"deleted": node_path})


func _duplicate_node(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var node := _resolve_node(node_path)
	if node == null:
		return _err("Node not found: %s" % node_path)

	var dup := node.duplicate(Node.DUPLICATE_USE_INSTANTIATION | Node.DUPLICATE_SIGNALS)
	var parent := node.get_parent()
	editor_plugin.get_undo_redo().create_action("MCP Duplicate Node")
	editor_plugin.get_undo_redo().add_do_method(parent, "add_child", dup, true)
	editor_plugin.get_undo_redo().add_do_method(dup, "set_owner", _edited_root())
	editor_plugin.get_undo_redo().add_undo_method(parent, "remove_child", dup)
	editor_plugin.get_undo_redo().commit_action()

	return _ok({"path": str(dup.get_path()), "name": dup.name})


func _move_node(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var new_parent_path: String = params.get("new_parent_path", ".")
	var node := _resolve_node(node_path)
	if node == null:
		return _err("Node not found: %s" % node_path)
	var new_parent := _resolve_node(new_parent_path)
	if new_parent == null:
		return _err("New parent not found: %s" % new_parent_path)

	var old_parent := node.get_parent()
	var old_index := node.get_index()
	editor_plugin.get_undo_redo().create_action("MCP Move Node")
	editor_plugin.get_undo_redo().add_do_method(old_parent, "remove_child", node)
	editor_plugin.get_undo_redo().add_do_method(new_parent, "add_child", node, true)
	editor_plugin.get_undo_redo().add_do_method(node, "set_owner", _edited_root())
	editor_plugin.get_undo_redo().add_undo_method(new_parent, "remove_child", node)
	editor_plugin.get_undo_redo().add_undo_method(old_parent, "add_child", node, true)
	editor_plugin.get_undo_redo().add_undo_method(old_parent, "move_child", node, old_index)
	editor_plugin.get_undo_redo().commit_action()

	return _ok({"path": str(node.get_path())})


func _rename_node(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var new_name: String = params.get("new_name", "")
	var node := _resolve_node(node_path)
	if node == null:
		return _err("Node not found: %s" % node_path)
	if new_name.is_empty():
		return _err("Missing 'new_name'")

	var old_name := node.name
	editor_plugin.get_undo_redo().create_action("MCP Rename Node")
	editor_plugin.get_undo_redo().add_do_property(node, "name", new_name)
	editor_plugin.get_undo_redo().add_undo_property(node, "name", old_name)
	editor_plugin.get_undo_redo().commit_action()

	return _ok({"path": str(node.get_path()), "name": new_name})


func _update_property(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var property: String = params.get("property", "")
	var value_text: String = str(params.get("value", ""))
	var node := _resolve_node(node_path)
	if node == null:
		return _err("Node not found: %s" % node_path)
	if property.is_empty():
		return _err("Missing 'property'")

	var parsed := TypeParser.parse(value_text)
	var old_value = node.get(property)
	editor_plugin.get_undo_redo().create_action("MCP Update Property")
	editor_plugin.get_undo_redo().add_do_property(node, property, parsed)
	editor_plugin.get_undo_redo().add_undo_property(node, property, old_value)
	editor_plugin.get_undo_redo().commit_action()

	return _ok({
		"node_path": str(node.get_path()),
		"property": property,
		"value": _serialize_value(parsed),
	})


func _get_node_properties(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var node := _resolve_node(node_path)
	if node == null:
		return _err("Node not found: %s" % node_path)

	var props := {}
	for info in node.get_property_list():
		if info.usage & PROPERTY_USAGE_EDITOR:
			var name: String = info.name
			props[name] = _serialize_value(node.get(name))
	return _ok({"node_path": str(node.get_path()), "type": node.get_class(), "properties": props})


func _get_signals(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var node := _resolve_node(node_path)
	if node == null:
		return _err("Node not found: %s" % node_path)

	var signals_out: Array = []
	for sig_info in node.get_signal_list():
		var connections: Array = []
		for conn in node.get_signal_connection_list(sig_info.name):
			connections.append({
				"target": str(conn.callable.get_object()),
				"method": conn.callable.get_method(),
			})
		signals_out.append({
			"name": sig_info.name,
			"connections": connections,
		})
	return _ok({"node_path": str(node.get_path()), "signals": signals_out})


func _add_resource(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var resource_type: String = params.get("resource_type", "")
	var node := _resolve_node(node_path)
	if node == null:
		return _err("Node not found")
	if not ClassDB.class_exists(resource_type):
		return _err("Unknown resource type: %s" % resource_type)
	var res: Resource = ClassDB.instantiate(resource_type)
	if node is CollisionShape2D and res is Shape2D:
		node.shape = res
	elif node is CollisionShape3D and res is Shape3D:
		node.shape = res
	elif node is MeshInstance3D and res is Mesh:
		node.mesh = res
	elif node is Sprite2D and res is Texture2D:
		node.texture = res
	else:
		return _err("Cannot auto-assign %s to %s" % [resource_type, node.get_class()])
	return _ok({"node_path": node_path, "resource_type": resource_type})


func _set_anchor_preset(params: Dictionary) -> Dictionary:
	var node_path: String = params.get("node_path", "")
	var preset_name: String = params.get("preset", "center")
	var node := _resolve_node(node_path)
	if node == null or not node is Control:
		return _err("Control node required")
	var preset_map := {
		"top_left": Control.PRESET_TOP_LEFT,
		"center": Control.PRESET_CENTER,
		"full_rect": Control.PRESET_FULL_RECT,
		"bottom_right": Control.PRESET_BOTTOM_RIGHT,
	}
	if not preset_map.has(preset_name):
		return _err("Unknown preset: %s" % preset_name)
	node.set_anchors_preset(preset_map[preset_name])
	return _ok({"node_path": node_path, "preset": preset_name})


func _connect_signal(params: Dictionary) -> Dictionary:
	var from_path: String = params.get("from_path", "")
	var signal_name: String = params.get("signal", "")
	var to_path: String = params.get("to_path", "")
	var method_name: String = params.get("method", "")
	var from_node := _resolve_node(from_path)
	var to_node := _resolve_node(to_path)
	if from_node == null or to_node == null:
		return _err("Source or target node not found")
	var err := from_node.connect(signal_name, Callable(to_node, method_name))
	if err != OK:
		return _err("Connect failed: %d" % err)
	return _ok({"connected": true})


func _disconnect_signal(params: Dictionary) -> Dictionary:
	var from_path: String = params.get("from_path", "")
	var signal_name: String = params.get("signal", "")
	var to_path: String = params.get("to_path", "")
	var method_name: String = params.get("method", "")
	var from_node := _resolve_node(from_path)
	var to_node := _resolve_node(to_path)
	if from_node == null or to_node == null:
		return _err("Source or target node not found")
	from_node.disconnect(signal_name, Callable(to_node, method_name))
	return _ok({"disconnected": true})


func _get_node_groups(params: Dictionary) -> Dictionary:
	var node := _resolve_node(params.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	return _ok({"groups": node.get_groups()})


func _set_node_groups(params: Dictionary) -> Dictionary:
	var node := _resolve_node(params.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	var groups: Array = params.get("groups", [])
	for g in node.get_groups():
		node.remove_from_group(g)
	for g in groups:
		node.add_to_group(str(g))
	return _ok({"groups": groups})


func _find_nodes_in_group(params: Dictionary) -> Dictionary:
	var group: String = params.get("group", "")
	var results: Array = []
	NodeUtils.collect_in_group(_edited_root(), group, results)
	return _ok({"group": group, "nodes": results})
