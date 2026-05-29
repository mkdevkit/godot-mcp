extends Node
## Queues synthetic input events for the running game/editor.

const QUEUE_FILE := "mcp_input_queue.json"


func queue_events(events: Array) -> void:
	var path := OS.get_user_data_dir().path_join(QUEUE_FILE)
	var existing: Array = []
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Array:
			existing = parsed
	existing.append_array(events)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(existing))
		file.close()


func _process(_delta: float) -> void:
	var path := OS.get_user_data_dir().path_join(QUEUE_FILE)
	if not FileAccess.file_exists(path):
		return
	var events = JSON.parse_string(FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(path)
	if not events is Array:
		return
	for ev in events:
		_apply(ev)


func _apply(ev: Dictionary) -> void:
	match ev.get("type", ""):
		"key":
			var e := InputEventKey.new()
			e.keycode = int(ev.get("keycode", 0))
			e.pressed = ev.get("pressed", true)
			Input.parse_input_event(e)
		"mouse_click":
			var e := InputEventMouseButton.new()
			e.position = Vector2(ev.get("x", 0), ev.get("y", 0))
			e.button_index = int(ev.get("button", MOUSE_BUTTON_LEFT))
			e.pressed = true
			Input.parse_input_event(e)
			e.pressed = false
			Input.parse_input_event(e)
		"mouse_move":
			var e := InputEventMouseMotion.new()
			e.position = Vector2(ev.get("x", 0), ev.get("y", 0))
			Input.parse_input_event(e)
		"action":
			if ev.get("pressed", true):
				Input.action_press(str(ev.get("action", "")))
			else:
				Input.action_release(str(ev.get("action", "")))
