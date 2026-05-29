@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"setup_physics_body": _setup_physics_body,
		"setup_collision": _setup_collision,
		"set_physics_layers": _set_physics_layers,
		"get_physics_layers": _get_physics_layers,
		"get_collision_info": _get_collision_info,
		"add_raycast": _add_raycast,
	}


func _setup_physics_body(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	if "gravity_scale" in node:
		node.gravity_scale = float(p.get("gravity_scale", 1.0))
	if "mass" in node:
		node.mass = float(p.get("mass", 1.0))
	if "lock_rotation" in node:
		node.lock_rotation = p.get("lock_rotation", false)
	return _ok({"node_path": str(node.get_path())})


func _setup_collision(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	var shape_type: String = p.get("shape_type", "rectangle")
	var shape: Shape2D = null
	match shape_type:
		"rectangle":
			var rect := RectangleShape2D.new()
			rect.size = Vector2(float(p.get("width", 32)), float(p.get("height", 32)))
			shape = rect
		"circle":
			var circle := CircleShape2D.new()
			circle.radius = float(p.get("radius", 16))
			shape = circle
		"box_3d":
			var col := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(float(p.get("width", 1)), float(p.get("height", 1)), float(p.get("depth", 1)))
			col.shape = box
			node.add_child(col, true)
			col.owner = _edited_root()
			return _ok({"added": "CollisionShape3D"})
	if shape and node is CollisionShape2D:
		node.shape = shape
	elif shape:
		var col := CollisionShape2D.new()
		col.shape = shape
		node.add_child(col, true)
		col.owner = _edited_root()
	return _ok({"shape": shape_type})


func _set_physics_layers(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	if "collision_layer" in node:
		node.collision_layer = int(p.get("layer", node.collision_layer))
	if "collision_mask" in node:
		node.collision_mask = int(p.get("mask", node.collision_mask))
	return _ok({"node_path": str(node.get_path())})


func _get_physics_layers(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	var layer: int = node.collision_layer if "collision_layer" in node else 0
	var mask: int = node.collision_mask if "collision_mask" in node else 0
	return _ok({
		"collision_layer": layer,
		"collision_mask": mask,
		"collision_layer_info": _layer_info(layer),
		"collision_mask_info": _layer_info(mask),
	})


func _layer_info(value: int) -> Array:
	var info: Array = []
	for i in 32:
		var bit := 1 << i
		if value & bit:
			var layer_name: String = ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % (i + 1), "")
			if layer_name.is_empty():
				layer_name = ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % (i + 1), "")
			info.append({"layer": i + 1, "bit": bit, "name": layer_name})
	return info


func _get_collision_info(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	var shapes: Array = []
	if node is CollisionShape2D or node is CollisionShape3D:
		shapes.append({"type": node.shape.get_class() if node.shape else "", "disabled": node.disabled})
	for child in node.get_children():
		if child is CollisionShape2D or child is CollisionShape3D:
			shapes.append({"path": str(child.get_path()), "type": child.shape.get_class() if child.shape else ""})
	return _ok({"shapes": shapes})


func _add_raycast(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var is_3d: bool = p.get("is_3d", false)
	var ray: Node = RayCast3D.new() if is_3d else RayCast2D.new()
	ray.name = p.get("name", "RayCast")
	parent.add_child(ray, true)
	ray.owner = _edited_root()
	return _ok({"path": str(ray.get_path())})
