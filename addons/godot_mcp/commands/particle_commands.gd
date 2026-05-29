@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"create_particles": _create_particles,
		"set_particle_material": _set_particle_material,
		"set_particle_color_gradient": _set_particle_color_gradient,
		"apply_particle_preset": _apply_particle_preset,
		"get_particle_info": _get_particle_info,
	}


func _create_particles(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var is_3d: bool = p.get("is_3d", true)
	var particles: Node = GPUParticles3D.new() if is_3d else GPUParticles2D.new()
	particles.name = p.get("name", "Particles")
	parent.add_child(particles, true)
	particles.owner = _edited_root()
	return _ok({"path": str(particles.get_path())})


func _set_particle_material(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = float(p.get("spread", 45.0))
	mat.initial_velocity_min = float(p.get("velocity_min", 1.0))
	mat.initial_velocity_max = float(p.get("velocity_max", 3.0))
	if node is GPUParticles3D:
		node.process_material = mat
	elif node is GPUParticles2D:
		node.process_material = mat
	return _ok({"path": str(node.get_path())})


func _set_particle_color_gradient(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	var grad := Gradient.new()
	grad.set_color(0, _parse_value(str(p.get("start_color", "#ff6600"))))
	grad.set_color(1, _parse_value(str(p.get("end_color", "#00000000"))))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	var mat: ParticleProcessMaterial = node.process_material if "process_material" in node else null
	if mat:
		mat.color_ramp = tex
	return _ok({"path": str(node.get_path())})


func _apply_particle_preset(p: Dictionary) -> Dictionary:
	var preset: String = p.get("preset", "fire")
	var base := {"node_path": p.get("node_path", "")}
	var params := {}
	match preset:
		"fire":
			params = {"spread": 25.0, "velocity_min": 2.0, "velocity_max": 5.0, "start_color": "#ff4400", "end_color": "#00000000"}
		"smoke":
			params = {"spread": 15.0, "velocity_min": 0.5, "velocity_max": 1.5, "start_color": "#888888", "end_color": "#00000000"}
		"sparks":
			params = {"spread": 60.0, "velocity_min": 3.0, "velocity_max": 8.0, "start_color": "#ffff00", "end_color": "#00000000"}
	var merged := base.merged(params)
	await _set_particle_material(merged)
	await _set_particle_color_gradient(merged)
	return _ok({"preset": preset})


func _get_particle_info(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	return _ok({
		"type": node.get_class(),
		"emitting": node.emitting if "emitting" in node else false,
		"amount": node.amount if "amount" in node else 0,
	})
