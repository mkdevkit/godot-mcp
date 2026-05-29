@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"setup_navigation_region": _setup_navigation_region,
		"setup_navigation_agent": _setup_navigation_agent,
		"bake_navigation_mesh": _bake_navigation_mesh,
		"set_navigation_layers": _set_navigation_layers,
		"get_navigation_info": _get_navigation_info,
		"get_navigation_path": _get_navigation_path,
	}


func _setup_navigation_region(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var region := NavigationRegion3D.new() if p.get("is_3d", true) else NavigationRegion2D.new()
	region.name = p.get("name", "NavigationRegion")
	parent.add_child(region, true)
	region.owner = _edited_root()
	return _ok({"path": str(region.get_path())})


func _setup_navigation_agent(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var agent := NavigationAgent3D.new() if p.get("is_3d", true) else NavigationAgent2D.new()
	agent.name = p.get("name", "NavigationAgent")
	if "max_speed" in agent:
		agent.max_speed = float(p.get("max_speed", 5.0))
	parent.add_child(agent, true)
	agent.owner = _edited_root()
	return _ok({"path": str(agent.get_path())})


func _bake_navigation_mesh(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	if node is NavigationRegion3D:
		node.bake_navigation_mesh()
	elif node is NavigationRegion2D:
		node.bake_navigation_polygon()
	else:
		return _err("NavigationRegion node required")
	return _ok({"baked": true})


func _set_navigation_layers(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	if "navigation_layers" in node:
		node.navigation_layers = int(p.get("layers", 1))
	return _ok({"layers": p.get("layers", 1)})


func _get_navigation_info(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	return _ok({
		"type": node.get_class(),
		"layers": node.navigation_layers if "navigation_layers" in node else 0,
	})


func _get_navigation_path(p: Dictionary) -> Dictionary:
	var map := NavigationServer2D.get_maps()
	if map.is_empty():
		return _ok({"path": [], "note": "No navigation map"})
	var from := Vector2(float(p.get("from_x", 0)), float(p.get("from_y", 0)))
	var to := Vector2(float(p.get("to_x", 0)), float(p.get("to_y", 0)))
	var path := NavigationServer2D.map_get_path(map[0], from, to, true)
	var points: Array = []
	for pt in path:
		points.append({"x": pt.x, "y": pt.y})
	return _ok({"path": points})
