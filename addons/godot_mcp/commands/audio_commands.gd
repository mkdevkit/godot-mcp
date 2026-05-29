@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"add_audio_player": _add_audio_player,
		"add_audio_bus": _add_audio_bus,
		"add_audio_bus_effect": _add_audio_bus_effect,
		"set_audio_bus": _set_audio_bus,
		"get_audio_bus_layout": _get_audio_bus_layout,
		"get_audio_info": _get_audio_info,
	}


func _add_audio_player(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var is_3d: bool = p.get("is_3d", false)
	var player: Node = AudioStreamPlayer3D.new() if is_3d else AudioStreamPlayer.new()
	player.name = p.get("name", "AudioStreamPlayer")
	var stream_path := _norm_res(p.get("stream_path", ""))
	if not stream_path.is_empty():
		player.stream = load(stream_path)
	parent.add_child(player, true)
	player.owner = _edited_root()
	return _ok({"path": str(player.get_path())})


func _add_audio_bus(p: Dictionary) -> Dictionary:
	var name: String = p.get("name", "NewBus")
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, name)
	return _ok({"bus_index": idx, "name": name})


func _add_audio_bus_effect(p: Dictionary) -> Dictionary:
	var bus_name: String = p.get("bus", "Master")
	var effect_type: String = p.get("effect_type", "reverb")
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return _err("Bus not found")
	var effect: AudioEffect = null
	match effect_type:
		"reverb":
			effect = AudioEffectReverb.new()
		"eq":
			effect = AudioEffectEQ.new()
		"compressor":
			effect = AudioEffectCompressor.new()
		_:
			return _err("Unknown effect type")
	AudioServer.add_bus_effect(idx, effect)
	return _ok({"bus": bus_name, "effect": effect_type})


func _set_audio_bus(p: Dictionary) -> Dictionary:
	var bus_name: String = p.get("bus", "Master")
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return _err("Bus not found")
	if p.has("volume_db"):
		AudioServer.set_bus_volume_db(idx, float(p.get("volume_db", 0)))
	if p.has("mute"):
		AudioServer.set_bus_mute(idx, p.get("mute", false))
	return _ok({"bus": bus_name})


func _get_audio_bus_layout(_p: Dictionary) -> Dictionary:
	var buses: Array = []
	for i in range(AudioServer.bus_count):
		buses.append({
			"index": i,
			"name": AudioServer.get_bus_name(i),
			"volume_db": AudioServer.get_bus_volume_db(i),
			"mute": AudioServer.is_bus_mute(i),
			"effects": AudioServer.get_bus_effect_count(i),
		})
	return _ok({"buses": buses})


func _get_audio_info(p: Dictionary) -> Dictionary:
	var node := _resolve_node(p.get("node_path", ""))
	if node == null:
		return _err("Node not found")
	return _ok({
		"type": node.get_class(),
		"playing": node.playing if "playing" in node else false,
		"stream": node.stream.resource_path if "stream" in node and node.stream else "",
	})
