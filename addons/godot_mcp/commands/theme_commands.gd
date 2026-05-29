@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"create_theme": _create_theme,
		"set_theme_color": _set_theme_color,
		"set_theme_constant": _set_theme_constant,
		"set_theme_font_size": _set_theme_font_size,
		"set_theme_stylebox": _set_theme_stylebox,
		"get_theme_info": _get_theme_info,
		"setup_control": _setup_control,
	}


func _create_theme(p: Dictionary) -> Dictionary:
	var path := _norm_res(p.get("theme_path", "res://theme.tres"))
	var theme := Theme.new()
	var err := ResourceSaver.save(theme, path)
	if err != OK:
		return _err("Failed to save theme")
	return _ok({"theme_path": path})


func _set_theme_color(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null or not node is Control:
		return _err("Control node required")
	node.add_theme_color_override(str(p.get("name", "")), _parse_value(str(p.get("color", "#ffffff"))))
	return _ok({"set": p.get("name", "")})


func _set_theme_constant(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null or not node is Control:
		return _err("Control node required")
	node.add_theme_constant_override(str(p.get("name", "")), int(p.get("value", 0)))
	return _ok({"set": p.get("name", "")})


func _set_theme_font_size(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null or not node is Control:
		return _err("Control node required")
	node.add_theme_font_size_override(str(p.get("name", "")), int(p.get("size", 16)))
	return _ok({"set": p.get("name", "")})


func _set_theme_stylebox(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null or not node is Control:
		return _err("Control node required")
	var style := StyleBoxFlat.new()
	style.bg_color = _parse_value(str(p.get("color", "#333333")))
	node.add_theme_stylebox_override(str(p.get("name", "panel")), style)
	return _ok({"set": p.get("name", "panel")})


func _get_theme_info(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null or not node is Control:
		return _err("Control node required")
	return _ok({
		"theme": node.theme.resource_path if node.theme else "",
		"has_overrides": true,
	})


func _setup_control(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null or not node is Control:
		return _err("Control node required")
	var applied: Array = []
	if p.has("anchor_preset"):
		var preset_map := {
			"top_left": Control.PRESET_TOP_LEFT,
			"top_right": Control.PRESET_TOP_RIGHT,
			"bottom_left": Control.PRESET_BOTTOM_LEFT,
			"bottom_right": Control.PRESET_BOTTOM_RIGHT,
			"center": Control.PRESET_CENTER,
			"full_rect": Control.PRESET_FULL_RECT,
			"center_top": Control.PRESET_CENTER_TOP,
			"center_bottom": Control.PRESET_CENTER_BOTTOM,
		}
		var preset_name: String = str(p.get("anchor_preset", "center"))
		if not preset_map.has(preset_name):
			return _err("Unknown anchor_preset: %s" % preset_name)
		node.set_anchors_preset(preset_map[preset_name])
		applied.append("anchor_preset")
	if p.has("size_flags_horizontal"):
		node.size_flags_horizontal = int(p.get("size_flags_horizontal"))
		applied.append("size_flags_horizontal")
	if p.has("size_flags_vertical"):
		node.size_flags_vertical = int(p.get("size_flags_vertical"))
		applied.append("size_flags_vertical")
	if p.has("custom_minimum_size"):
		var cms = p.get("custom_minimum_size", {})
		node.custom_minimum_size = Vector2(float(cms.get("x", 0)), float(cms.get("y", 0)))
		applied.append("custom_minimum_size")
	if p.has("offset_left"):
		node.offset_left = float(p.get("offset_left"))
		applied.append("offset_left")
	if p.has("offset_top"):
		node.offset_top = float(p.get("offset_top"))
		applied.append("offset_top")
	if p.has("offset_right"):
		node.offset_right = float(p.get("offset_right"))
		applied.append("offset_right")
	if p.has("offset_bottom"):
		node.offset_bottom = float(p.get("offset_bottom"))
		applied.append("offset_bottom")
	if p.has("text") and "text" in node:
		node.text = str(p.get("text"))
		applied.append("text")
	return _ok({"node_path": str(node.get_path()), "applied": applied})
