@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"list_animations": _list_animations,
		"create_animation": _create_animation,
		"add_animation_track": _add_animation_track,
		"set_animation_keyframe": _set_animation_keyframe,
		"get_animation_info": _get_animation_info,
		"remove_animation": _remove_animation,
	}


func _get_player(path: String) -> AnimationPlayer:
	var node := _resolve_node(path)
	if node is AnimationPlayer:
		return node
	return null


func _list_animations(p: Dictionary) -> Dictionary:
	var player := _get_player(p.get("node_path", ""))
	if player == null:
		return _err("AnimationPlayer not found")
	return _ok({"animations": player.get_animation_list()})


func _create_animation(p: Dictionary) -> Dictionary:
	var player := _get_player(p.get("node_path", ""))
	var anim_name: String = p.get("name", "new_animation")
	if player == null:
		return _err("AnimationPlayer not found")
	var anim := Animation.new()
	anim.length = float(p.get("length", 1.0))
	player.add_animation_library("", AnimationLibrary.new()) if player.get_animation_library("") == null else null
	player.get_animation_library("").add_animation(anim_name, anim)
	return _ok({"animation": anim_name})


func _add_animation_track(p: Dictionary) -> Dictionary:
	var player := _get_player(p.get("node_path", ""))
	var anim_name: String = p.get("animation", "")
	if player == null:
		return _err("AnimationPlayer not found")
	var anim: Animation = player.get_animation(anim_name)
	if anim == null:
		return _err("Animation not found")
	var track_type: String = p.get("track_type", "value")
	var path: NodePath = NodePath(str(p.get("property_path", "")))
	var idx := -1
	match track_type:
		"value":
			idx = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(idx, path)
		"position_3d":
			idx = anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(idx, path)
		"rotation_3d":
			idx = anim.add_track(Animation.TYPE_ROTATION_3D)
			anim.track_set_path(idx, path)
		"method":
			idx = anim.add_track(Animation.TYPE_METHOD)
			anim.track_set_path(idx, path)
		_:
			return _err("Unknown track_type")
	return _ok({"track_index": idx})


func _set_animation_keyframe(p: Dictionary) -> Dictionary:
	var player := _get_player(p.get("node_path", ""))
	var anim: Animation = player.get_animation(p.get("animation", "")) if player else null
	if anim == null:
		return _err("Animation not found")
	var track: int = int(p.get("track", 0))
	var time: float = float(p.get("time", 0.0))
	var value = _parse_value(str(p.get("value", "0")))
	anim.track_insert_key(track, time, value)
	return _ok({"track": track, "time": time})


func _get_animation_info(p: Dictionary) -> Dictionary:
	var player := _get_player(p.get("node_path", ""))
	var anim_name: String = p.get("animation", "")
	if player == null:
		return _err("AnimationPlayer not found")
	var anim: Animation = player.get_animation(anim_name)
	if anim == null:
		return _err("Animation not found")
	var tracks: Array = []
	for i in anim.get_track_count():
		tracks.append({
			"index": i,
			"type": anim.track_get_type(i),
			"path": str(anim.track_get_path(i)),
			"keys": anim.track_get_key_count(i),
		})
	return _ok({"name": anim_name, "length": anim.length, "tracks": tracks})


func _remove_animation(p: Dictionary) -> Dictionary:
	var player := _get_player(p.get("node_path", ""))
	var anim_name: String = p.get("animation", "")
	if player == null:
		return _err("AnimationPlayer not found")
	player.get_animation_library("").remove_animation(anim_name)
	return _ok({"removed": anim_name})
