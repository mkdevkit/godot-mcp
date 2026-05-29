@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"list_android_devices": _list_android_devices,
		"deploy_to_android": _deploy_to_android,
		"get_android_build_info": _get_android_build_info,
		"get_android_preset_info": _get_android_preset_info,
	}


func _run_shell(command: String, args: PackedStringArray) -> Dictionary:
	var output: Array = []
	var exit_code := OS.execute(command, args, output, true, false)
	return {"exit_code": exit_code, "output": "\n".join(PackedStringArray(output)).strip_edges()}


func _read_export_presets() -> Array:
	var path := "res://export_presets.cfg"
	if not FileAccess.file_exists(path):
		return []
	var cfg := ConfigFile.new()
	cfg.load(path)
	var presets: Array = []
	for section in cfg.get_sections():
		if section.begins_with("preset."):
			presets.append({
				"name": cfg.get_value(section, "name", section),
				"platform": cfg.get_value(section, "platform", ""),
				"section": section,
				"cfg": cfg,
				"section_id": section,
			})
	return presets


func _find_android_preset(preset_name: String = "") -> Dictionary:
	for preset in _read_export_presets():
		if preset.platform != "Android":
			continue
		if preset_name.is_empty() or preset.name == preset_name:
			return preset
	return {}


func _list_android_devices(_p: Dictionary) -> Dictionary:
	var result := _run_shell("adb", PackedStringArray(["devices"]))
	if result.exit_code != 0:
		return _ok({
			"devices": [],
			"adb_available": false,
			"output": result.output,
			"note": "Install Android SDK platform-tools and ensure adb is in PATH",
		})
	var devices: Array = []
	for line in result.output.split("\n"):
		if line.contains("\tdevice"):
			devices.append(line.split("\t")[0])
	return _ok({"devices": devices, "adb_available": true, "count": devices.size()})


func _get_android_preset_info(p: Dictionary) -> Dictionary:
	var preset_name: String = p.get("preset", "")
	var preset := _find_android_preset(preset_name)
	if preset.is_empty():
		return _err("Android export preset not found")
	var cfg: ConfigFile = preset.cfg
	var section: String = preset.section_id
	var options: Dictionary = {}
	for key in cfg.get_section_keys(section):
		if key.begins_with("options/"):
			options[key.trim_prefix("options/")] = cfg.get_value(section, key)
	return _ok({
		"preset": preset.name,
		"platform": preset.platform,
		"package": options.get("package/unique_name", ProjectSettings.get_setting("application/config/name", "")),
		"version_code": options.get("version/code", ProjectSettings.get_setting("application/config/version", "")),
		"version_name": options.get("version/name", ""),
		"min_sdk": options.get("gradle_build/min_sdk", ""),
		"target_sdk": options.get("gradle_build/target_sdk", ""),
		"architectures": options.get("architectures", ""),
		"options": options,
	})


func _get_android_build_info(_p: Dictionary) -> Dictionary:
	var preset_info := _get_android_preset_info({})
	if preset_info.has("error"):
		return _ok({
			"package": ProjectSettings.get_setting("application/config/name", ""),
			"version": ProjectSettings.get_setting("application/config/version", ""),
			"min_sdk": ProjectSettings.get_setting("application/config/android_minimum_sdk", ""),
			"target_sdk": ProjectSettings.get_setting("application/config/android_target_sdk", ""),
		})
	return preset_info


func _deploy_to_android(p: Dictionary) -> Dictionary:
	var preset_name: String = p.get("preset", "")
	var apk_path: String = p.get("apk_path", "build/android_debug.apk")
	var device_id: String = p.get("device_id", "")
	var preset := _find_android_preset(preset_name)
	if preset.is_empty():
		return _err("Android export preset not found")
	var global_apk := _globalize_apk_path(apk_path)
	var project_path := ProjectSettings.globalize_path("res://")
	var godot_bin := OS.get_executable_path()
	var export_args := PackedStringArray([
		"--headless", "--path", project_path,
		"--export-debug", preset.name, global_apk,
	])
	var export_result := _run_shell(godot_bin, export_args)
	if export_result.exit_code != 0:
		return _err("Export failed: %s" % export_result.output)
	var install_args := PackedStringArray(["install", "-r", global_apk])
	if not device_id.is_empty():
		install_args = PackedStringArray(["-s", device_id, "install", "-r", global_apk])
	var install_result := _run_shell("adb", install_args)
	if install_result.exit_code != 0:
		return _err("Install failed: %s" % install_result.output)
	var preset_data := _get_android_preset_info({"preset": preset.name})
	var package_name := str(preset_data.get("result", {}).get("package", ""))
	if not package_name.is_empty() and p.get("launch", true):
		var launch_args := PackedStringArray(["shell", "monkey", "-p", package_name, "-c", "android.intent.category.LAUNCHER", "1"])
		if not device_id.is_empty():
			launch_args = PackedStringArray(["-s", device_id, "shell", "monkey", "-p", package_name, "-c", "android.intent.category.LAUNCHER", "1"])
		_run_shell("adb", launch_args)
	return _ok({
		"exported": true,
		"installed": true,
		"apk_path": apk_path,
		"preset": preset.name,
		"export_output": export_result.output,
		"install_output": install_result.output,
	})


func _globalize_apk_path(path: String) -> String:
	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	if not path.begins_with("/") and not path.contains(":"):
		return ProjectSettings.globalize_path("res://" + path)
	return path
