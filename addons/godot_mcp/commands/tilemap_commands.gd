@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func _get_layer(path: String) -> TileMapLayer:
	var node := _resolve_node(path)
	return node if node is TileMapLayer else null


func get_commands() -> Dictionary:
	return {
		"tilemap_set_cell": _tilemap_set_cell,
		"tilemap_fill_rect": _tilemap_fill_rect,
		"tilemap_get_cell": _tilemap_get_cell,
		"tilemap_clear": _tilemap_clear,
		"tilemap_get_info": _tilemap_get_info,
		"tilemap_get_used_cells": _tilemap_get_used_cells,
	}


func _tilemap_set_cell(p: Dictionary) -> Dictionary:
	var layer := _get_layer(p.get("node_path", ""))
	if layer == null:
		return _err("TileMapLayer not found")
	var coords := Vector2i(int(p.get("x", 0)), int(p.get("y", 0)))
	layer.set_cell(coords, int(p.get("source", 0)), Vector2i(int(p.get("atlas_x", 0)), int(p.get("atlas_y", 0))))
	return _ok({"cell": coords})


func _tilemap_fill_rect(p: Dictionary) -> Dictionary:
	var layer := _get_layer(p.get("node_path", ""))
	if layer == null:
		return _err("TileMapLayer not found")
	var rect := Rect2i(
		int(p.get("x", 0)), int(p.get("y", 0)),
		int(p.get("width", 1)), int(p.get("height", 1))
	)
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			layer.set_cell(Vector2i(x, y), int(p.get("source", 0)), Vector2i(int(p.get("atlas_x", 0)), int(p.get("atlas_y", 0))))
	return _ok({"filled": rect})


func _tilemap_get_cell(p: Dictionary) -> Dictionary:
	var layer := _get_layer(p.get("node_path", ""))
	if layer == null:
		return _err("TileMapLayer not found")
	var coords := Vector2i(int(p.get("x", 0)), int(p.get("y", 0)))
	var source := layer.get_cell_source_id(coords)
	var atlas := layer.get_cell_atlas_coords(coords)
	return _ok({"source": source, "atlas": atlas})


func _tilemap_clear(p: Dictionary) -> Dictionary:
	var layer := _get_layer(p.get("node_path", ""))
	if layer == null:
		return _err("TileMapLayer not found")
	layer.clear()
	return _ok({"cleared": true})


func _tilemap_get_info(p: Dictionary) -> Dictionary:
	var layer := _get_layer(p.get("node_path", ""))
	if layer == null:
		return _err("TileMapLayer not found")
	var ts := layer.tile_set
	return _ok({
		"tile_set": ts.resource_path if ts else "",
		"sources": ts.get_source_count() if ts else 0,
	})


func _tilemap_get_used_cells(p: Dictionary) -> Dictionary:
	var layer := _get_layer(p.get("node_path", ""))
	if layer == null:
		return _err("TileMapLayer not found")
	var cells: Array = []
	for c in layer.get_used_cells():
		cells.append({"x": c.x, "y": c.y})
	return _ok({"cells": cells, "count": cells.size()})
