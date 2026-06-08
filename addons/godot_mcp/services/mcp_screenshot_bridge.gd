extends Node
## Captures editor/game viewport screenshots on demand.

const REQUEST_FILE := "mcp_screenshot_req.json"
const RESPONSE_FILE := "mcp_screenshot_res.png"
const META_FILE := "mcp_screenshot_meta.json"


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		_check_game_request()
		return
	_check_editor_request()


func _check_editor_request() -> void:
	var req_path := _user_path(REQUEST_FILE)
	if not FileAccess.file_exists(req_path):
		return
	var req := JSON.parse_string(FileAccess.get_file_as_string(req_path))
	DirAccess.remove_absolute(req_path)
	if req is Dictionary and req.get("target") == "game":
		return
	_capture_viewport()


func _check_game_request() -> void:
	var req_path := _user_path(REQUEST_FILE)
	if not FileAccess.file_exists(req_path):
		return
	var req := JSON.parse_string(FileAccess.get_file_as_string(req_path))
	DirAccess.remove_absolute(req_path)
	if req is Dictionary and req.get("target") == "game":
		_capture_viewport()


func _capture_viewport() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var tex := viewport.get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img:
		img.save_png(_user_path(RESPONSE_FILE))
		var meta := FileAccess.open(_user_path(META_FILE), FileAccess.WRITE)
		if meta:
			meta.store_string(JSON.stringify({"width": img.get_width(), "height": img.get_height()}))
			meta.close()


func _user_path(file: String) -> String:
	return OS.get_user_data_dir().path_join(file)
