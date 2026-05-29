@tool
extends RefCounted
class_name MCPTypeParser

static func parse(text: String) -> Variant:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return ""
	if trimmed == "true":
		return true
	if trimmed == "false":
		return false
	if trimmed == "null":
		return null
	if trimmed.is_valid_int():
		return int(trimmed)
	if trimmed.is_valid_float():
		return float(trimmed)
	if trimmed.begins_with("Vector2(") and trimmed.ends_with(")"):
		return _parse_vector2(trimmed)
	if trimmed.begins_with("Vector3(") and trimmed.ends_with(")"):
		return _parse_vector3(trimmed)
	if trimmed.begins_with("Color(") and trimmed.ends_with(")"):
		return _parse_color(trimmed)
	if trimmed.begins_with("#") and trimmed.length() in [4, 5, 7, 9]:
		return Color(trimmed)
	if trimmed.begins_with("res://"):
		return trimmed
	return trimmed


static func _parse_vector2(text: String) -> Vector2:
	var inner := text.trim_prefix("Vector2(").trim_suffix(")")
	var parts := inner.split(",")
	if parts.size() >= 2:
		return Vector2(float(parts[0].strip_edges()), float(parts[1].strip_edges()))
	return Vector2.ZERO


static func _parse_vector3(text: String) -> Vector3:
	var inner := text.trim_prefix("Vector3(").trim_suffix(")")
	var parts := inner.split(",")
	if parts.size() >= 3:
		return Vector3(float(parts[0].strip_edges()), float(parts[1].strip_edges()), float(parts[2].strip_edges()))
	return Vector3.ZERO


static func _parse_color(text: String) -> Color:
	var inner := text.trim_prefix("Color(").trim_suffix(")")
	var parts := inner.split(",")
	if parts.size() >= 3:
		var a := 1.0
		if parts.size() >= 4:
			a = float(parts[3].strip_edges())
		return Color(float(parts[0].strip_edges()), float(parts[1].strip_edges()), float(parts[2].strip_edges()), a)
	return Color.WHITE
