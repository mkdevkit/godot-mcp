@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"add_mesh_instance": _add_mesh_instance,
		"setup_camera_3d": _setup_camera_3d,
		"setup_lighting": _setup_lighting,
		"setup_environment": _setup_environment,
		"add_gridmap": _add_gridmap,
		"set_material_3d": _set_material_3d,
	}


func _add_mesh_instance(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = p.get("name", "MeshInstance3D")
	var primitive: String = p.get("primitive", "box")
	var mesh: Mesh = null
	match primitive:
		"box":
			var bm := BoxMesh.new()
			bm.size = Vector3(float(p.get("size", 1)), float(p.get("size", 1)), float(p.get("size", 1)))
			mesh = bm
		"sphere":
			var sm := SphereMesh.new()
			sm.radius = float(p.get("radius", 0.5))
			mesh = sm
		"plane":
			mesh = PlaneMesh.new()
	mesh_node.mesh = mesh
	parent.add_child(mesh_node, true)
	mesh_node.owner = _edited_root()
	return _ok({"path": str(mesh_node.get_path())})


func _setup_camera_3d(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null or not node is Camera3D:
		return _err("Camera3D required")
	node.fov = float(p.get("fov", node.fov))
	node.current = p.get("current", node.current)
	node.position = Vector3(float(p.get("x", node.position.x)), float(p.get("y", node.position.y)), float(p.get("z", node.position.z)))
	return _ok({"path": str(node.get_path())})


func _setup_lighting(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var light_type: String = p.get("type", "directional")
	var light: Light3D = DirectionalLight3D.new()
	if light_type == "omni":
		light = OmniLight3D.new()
	elif light_type == "spot":
		light = SpotLight3D.new()
	light.name = p.get("name", "Light3D")
	light.light_energy = float(p.get("energy", 1.0))
	parent.add_child(light, true)
	light.owner = _edited_root()
	return _ok({"path": str(light.get_path())})


func _setup_environment(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var env_node := WorldEnvironment.new()
	env_node.name = p.get("name", "WorldEnvironment")
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _parse_value(str(p.get("background_color", "#1a1a2e")))
	env_node.environment = env
	parent.add_child(env_node, true)
	env_node.owner = _edited_root()
	return _ok({"path": str(env_node.get_path())})


func _add_gridmap(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var grid := GridMap.new()
	grid.name = p.get("name", "GridMap")
	var mesh_path := _norm_res(p.get("mesh_library", ""))
	if not mesh_path.is_empty():
		grid.mesh_library = load(mesh_path)
	parent.add_child(grid, true)
	grid.owner = _edited_root()
	return _ok({"path": str(grid.get_path())})


func _set_material_3d(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null or not node is MeshInstance3D:
		return _err("MeshInstance3D required")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _parse_value(str(p.get("color", "#ffffff")))
	node.material_override = mat
	return _ok({"path": str(node.get_path())})
