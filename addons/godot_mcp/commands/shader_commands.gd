@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"create_shader": _create_shader,
		"read_shader": _read_shader,
		"edit_shader": _edit_shader,
		"assign_shader_material": _assign_shader_material,
		"set_shader_param": _set_shader_param,
		"get_shader_params": _get_shader_params,
	}


func _create_shader(p: Dictionary) -> Dictionary:
	var path := _norm_res(p.get("shader_path", "res://shader.gdshader"))
	var shader_type: String = p.get("type", "spatial")
	var template := "shader_type %s;\n\nvoid fragment() {\n\tCOLOR = vec4(1.0);\n}\n" % shader_type
	if ResourceUtils.write_text(path, p.get("content", template)) != OK:
		return _err("Failed to write shader")
	return _ok({"shader_path": path})


func _read_shader(p: Dictionary) -> Dictionary:
	var path := _norm_res(p.get("shader_path", ""))
	return _ok({"content": ResourceUtils.read_text(path)})


func _edit_shader(p: Dictionary) -> Dictionary:
	var path := _norm_res(p.get("shader_path", ""))
	var content: String = p.get("content", "")
	if content.is_empty():
		var existing := ResourceUtils.read_text(path)
		content = existing.replace(p.get("search", ""), p.get("replace", ""))
	ResourceUtils.write_text(path, content)
	editor_plugin.get_editor_interface().get_resource_filesystem().scan()
	return _ok({"updated": path})


func _assign_shader_material(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	var shader_path := _norm_res(p.get("shader_path", ""))
	var shader: Shader = load(shader_path)
	if shader == null:
		return _err("Shader not found")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	if node is CanvasItem or node is GeometryInstance3D:
		node.material = mat
	return _ok({"node_path": str(node.get_path())})


func _set_shader_param(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	var mat: ShaderMaterial = node.material if "material" in node else null
	if mat == null:
		return _err("No ShaderMaterial on node")
	mat.set_shader_parameter(str(p.get("param", "")), _parse_value(str(p.get("value", ""))))
	return _ok({"param": p.get("param", "")})


func _get_shader_params(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	var mat: ShaderMaterial = node.material if "material" in node else null
	if mat == null or mat.shader == null:
		return _err("No shader material")
	var params := {}
	for uniform in mat.shader.get_shader_uniform_list():
		params[uniform.name] = str(mat.get_shader_parameter(uniform.name))
	return _ok({"params": params})
