export interface ToolParamDef {
  name: string;
  type: "string" | "number" | "boolean" | "array" | "record";
  required?: boolean;
  description?: string;
  enum?: string[];
}

export interface ToolDef {
  name: string;
  description: string;
  method: string;
  params?: ToolParamDef[];
}

export const TOOL_DEFINITIONS: ToolDef[] = [
  // Project (7)
  { name: "get_project_info", description: "Project metadata, version, viewport, autoloads", method: "get_project_info" },
  { name: "get_filesystem_tree", description: "Recursive file tree with filtering", method: "get_filesystem_tree", params: [{ name: "directory", type: "string" }, { name: "max_depth", type: "number" }] },
  { name: "search_files", description: "Fuzzy/glob file search", method: "search_files", params: [{ name: "pattern", type: "string" }, { name: "directory", type: "string" }, { name: "recursive", type: "boolean" }, { name: "max_results", type: "number" }] },
  { name: "get_project_settings", description: "Read project.godot settings", method: "get_project_settings", params: [{ name: "keys", type: "array" }] },
  { name: "set_project_setting", description: "Set project settings via editor API", method: "set_project_setting", params: [{ name: "key", type: "string", required: true }, { name: "value", type: "string", required: true }] },
  { name: "uid_to_project_path", description: "UID to res:// conversion", method: "uid_to_project_path", params: [{ name: "uid", type: "string", required: true }] },
  { name: "project_path_to_uid", description: "res:// to UID conversion", method: "project_path_to_uid", params: [{ name: "path", type: "string", required: true }] },

  // Scene (9)
  { name: "get_scene_tree", description: "Live scene tree with hierarchy", method: "get_scene_tree" },
  { name: "get_scene_file_content", description: "Raw .tscn file content", method: "get_scene_file_content", params: [{ name: "scene_path", type: "string" }] },
  { name: "create_scene", description: "Create new scene files", method: "create_scene", params: [{ name: "scene_path", type: "string", required: true }, { name: "root_type", type: "string" }, { name: "overwrite", type: "boolean" }] },
  { name: "open_scene", description: "Open scene in editor", method: "open_scene", params: [{ name: "scene_path", type: "string", required: true }] },
  { name: "delete_scene", description: "Delete scene file", method: "delete_scene", params: [{ name: "scene_path", type: "string", required: true }] },
  { name: "add_scene_instance", description: "Instance scene as child node", method: "add_scene_instance", params: [{ name: "scene_path", type: "string", required: true }, { name: "parent_path", type: "string" }, { name: "name", type: "string" }] },
  { name: "play_scene", description: "Run scene (main/current/custom)", method: "play_scene", params: [{ name: "mode", type: "string", enum: ["current", "main", "custom"] }, { name: "scene_path", type: "string" }] },
  { name: "stop_scene", description: "Stop running scene", method: "stop_scene" },
  { name: "save_scene", description: "Save current scene to disk", method: "save_scene" },
  { name: "get_scene_exports", description: "List @export variables in a scene", method: "get_scene_exports", params: [{ name: "scene_path", type: "string" }, { name: "path", type: "string" }] },

  // Node (14)
  { name: "add_node", description: "Add node with type and properties", method: "add_node", params: [{ name: "type", type: "string", required: true }, { name: "name", type: "string" }, { name: "parent_path", type: "string" }, { name: "properties", type: "record" }] },
  { name: "delete_node", description: "Delete node (with undo support)", method: "delete_node", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "duplicate_node", description: "Duplicate node and children", method: "duplicate_node", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "move_node", description: "Move/reparent node", method: "move_node", params: [{ name: "node_path", type: "string", required: true }, { name: "new_parent_path", type: "string", required: true }] },
  { name: "update_property", description: "Set any property (auto type parsing)", method: "update_property", params: [{ name: "node_path", type: "string", required: true }, { name: "property", type: "string", required: true }, { name: "value", type: "string", required: true }] },
  { name: "get_node_properties", description: "Get all node properties", method: "get_node_properties", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "add_resource", description: "Add Shape/Material/etc to node", method: "add_resource", params: [{ name: "node_path", type: "string", required: true }, { name: "resource_type", type: "string", required: true }] },
  { name: "set_anchor_preset", description: "Set Control anchor preset", method: "set_anchor_preset", params: [{ name: "node_path", type: "string", required: true }, { name: "preset", type: "string" }] },
  { name: "rename_node", description: "Rename a node in the scene", method: "rename_node", params: [{ name: "node_path", type: "string", required: true }, { name: "new_name", type: "string", required: true }] },
  { name: "connect_signal", description: "Connect signal between nodes", method: "connect_signal", params: [{ name: "from_path", type: "string", required: true }, { name: "signal", type: "string", required: true }, { name: "to_path", type: "string", required: true }, { name: "method", type: "string", required: true }] },
  { name: "disconnect_signal", description: "Disconnect signal connection", method: "disconnect_signal", params: [{ name: "from_path", type: "string", required: true }, { name: "signal", type: "string", required: true }, { name: "to_path", type: "string", required: true }, { name: "method", type: "string", required: true }] },
  { name: "get_node_groups", description: "Get groups a node belongs to", method: "get_node_groups", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "set_node_groups", description: "Set node group membership", method: "set_node_groups", params: [{ name: "node_path", type: "string", required: true }, { name: "groups", type: "array", required: true }] },
  { name: "find_nodes_in_group", description: "Find all nodes in a group", method: "find_nodes_in_group", params: [{ name: "group", type: "string", required: true }] },

  // Script (8)
  { name: "list_scripts", description: "List all scripts with class info", method: "list_scripts" },
  { name: "read_script", description: "Read script content", method: "read_script", params: [{ name: "script_path", type: "string", required: true }] },
  { name: "create_script", description: "Create new script with template", method: "create_script", params: [{ name: "script_path", type: "string", required: true }, { name: "content", type: "string" }, { name: "overwrite", type: "boolean" }] },
  { name: "edit_script", description: "Search/replace or full edit", method: "edit_script", params: [{ name: "script_path", type: "string", required: true }, { name: "content", type: "string" }, { name: "search", type: "string" }, { name: "replace", type: "string" }] },
  { name: "attach_script", description: "Attach script to node", method: "attach_script", params: [{ name: "node_path", type: "string", required: true }, { name: "script_path", type: "string", required: true }] },
  { name: "get_open_scripts", description: "List scripts open in editor", method: "get_open_scripts" },
  { name: "validate_script", description: "Validate GDScript syntax", method: "validate_script", params: [{ name: "script_path", type: "string" }, { name: "content", type: "string" }] },
  { name: "search_in_files", description: "Search content in project files", method: "search_in_files", params: [{ name: "query", type: "string", required: true }, { name: "directory", type: "string" }, { name: "max_results", type: "number" }] },

  // Editor (9)
  { name: "get_editor_errors", description: "Get errors and stack traces", method: "get_editor_errors" },
  { name: "get_editor_screenshot", description: "Capture editor viewport", method: "get_editor_screenshot" },
  { name: "get_game_screenshot", description: "Capture running game", method: "get_game_screenshot" },
  { name: "execute_editor_script", description: "Run arbitrary GDScript in editor", method: "execute_editor_script", params: [{ name: "code", type: "string", required: true }] },
  { name: "clear_output", description: "Clear output panel", method: "clear_output" },
  { name: "get_signals", description: "Get all signals of a node with connections", method: "get_signals", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "reload_plugin", description: "Reload the MCP plugin", method: "reload_plugin" },
  { name: "reload_project", description: "Rescan filesystem and reload scripts", method: "reload_project" },
  { name: "get_output_log", description: "Get output panel content", method: "get_output_log", params: [{ name: "max_lines", type: "number" }] },
  { name: "get_editor_camera", description: "Get 3D editor viewport camera transform", method: "get_editor_camera" },
  { name: "set_editor_camera", description: "Set 3D editor viewport camera transform", method: "set_editor_camera", params: [{ name: "viewport_index", type: "number" }, { name: "x", type: "number" }, { name: "y", type: "number" }, { name: "z", type: "number" }, { name: "rotation_x", type: "number" }, { name: "rotation_y", type: "number" }, { name: "rotation_z", type: "number" }] },
  { name: "set_auto_dismiss", description: "Auto-dismiss editor dialog popups", method: "set_auto_dismiss", params: [{ name: "enabled", type: "boolean" }] },
  { name: "compare_screenshots", description: "Compare two screenshot images", method: "compare_screenshots", params: [{ name: "path_a", type: "string", required: true }, { name: "path_b", type: "string", required: true }] },

  // Input (7)
  { name: "simulate_key", description: "Simulate keyboard key press/release", method: "simulate_key", params: [{ name: "keycode", type: "number" }, { name: "pressed", type: "boolean" }] },
  { name: "simulate_mouse_click", description: "Simulate mouse click at position", method: "simulate_mouse_click", params: [{ name: "x", type: "number" }, { name: "y", type: "number" }, { name: "button", type: "number" }] },
  { name: "simulate_mouse_move", description: "Simulate mouse movement", method: "simulate_mouse_move", params: [{ name: "x", type: "number" }, { name: "y", type: "number" }] },
  { name: "simulate_action", description: "Simulate Godot Input Action", method: "simulate_action", params: [{ name: "action", type: "string", required: true }, { name: "pressed", type: "boolean" }] },
  { name: "simulate_sequence", description: "Sequence of input events", method: "simulate_sequence", params: [{ name: "events", type: "array", required: true }] },
  { name: "get_input_actions", description: "List all input actions", method: "get_input_actions" },
  { name: "set_input_action", description: "Create/modify input action", method: "set_input_action", params: [{ name: "action", type: "string", required: true }, { name: "keycode", type: "number" }] },

  // Runtime (19)
  { name: "get_game_scene_tree", description: "Scene tree of running game", method: "get_game_scene_tree" },
  { name: "get_game_node_properties", description: "Node properties in running game", method: "get_game_node_properties", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "set_game_node_property", description: "Set node property in running game", method: "set_game_node_property", params: [{ name: "node_path", type: "string", required: true }, { name: "property", type: "string", required: true }, { name: "value", type: "string", required: true }] },
  { name: "execute_game_script", description: "Run GDScript in game context", method: "execute_game_script", params: [{ name: "code", type: "string", required: true }] },
  { name: "capture_frames", description: "Multi-frame screenshot capture", method: "capture_frames", params: [{ name: "count", type: "number" }] },
  { name: "monitor_properties", description: "Record property values over time", method: "monitor_properties", params: [{ name: "key", type: "string" }, { name: "node_path", type: "string" }, { name: "property", type: "string" }] },
  { name: "start_recording", description: "Start input recording", method: "start_recording" },
  { name: "stop_recording", description: "Stop input recording", method: "stop_recording" },
  { name: "replay_recording", description: "Replay recorded input", method: "replay_recording", params: [{ name: "events", type: "array" }] },
  { name: "find_nodes_by_script", description: "Find game nodes by script", method: "find_nodes_by_script", params: [{ name: "script_path", type: "string", required: true }] },
  { name: "get_autoload", description: "Get autoload node properties", method: "get_autoload", params: [{ name: "name", type: "string", required: true }] },
  { name: "batch_get_properties", description: "Batch get multiple node properties", method: "batch_get_properties", params: [{ name: "nodes", type: "array", required: true }] },
  { name: "find_ui_elements", description: "Find UI elements in game", method: "find_ui_elements" },
  { name: "click_button_by_text", description: "Click button by text content", method: "click_button_by_text", params: [{ name: "text", type: "string", required: true }] },
  { name: "wait_for_node", description: "Wait for node to appear", method: "wait_for_node", params: [{ name: "node_path", type: "string", required: true }, { name: "timeout", type: "number" }] },
  { name: "find_nearby_nodes", description: "Find nodes near position", method: "find_nearby_nodes", params: [{ name: "x", type: "number" }, { name: "y", type: "number" }, { name: "radius", type: "number" }] },
  { name: "navigate_to", description: "Navigate to target position", method: "navigate_to", params: [{ name: "agent_path", type: "string" }, { name: "x", type: "number" }, { name: "y", type: "number" }] },
  { name: "move_to", description: "Walk character to target", method: "move_to", params: [{ name: "agent_path", type: "string" }, { name: "x", type: "number" }, { name: "y", type: "number" }] },
  { name: "watch_signals", description: "Watch signal emissions during gameplay", method: "watch_signals", params: [{ name: "node_paths", type: "array", required: true }, { name: "duration_ms", type: "number" }, { name: "signal_filter", type: "array" }] },

  // Animation (6)
  { name: "list_animations", description: "List all animations in AnimationPlayer", method: "list_animations", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "create_animation", description: "Create new animation", method: "create_animation", params: [{ name: "node_path", type: "string", required: true }, { name: "name", type: "string" }, { name: "length", type: "number" }] },
  { name: "add_animation_track", description: "Add animation track", method: "add_animation_track", params: [{ name: "node_path", type: "string", required: true }, { name: "animation", type: "string", required: true }, { name: "track_type", type: "string" }, { name: "property_path", type: "string" }] },
  { name: "set_animation_keyframe", description: "Insert keyframe into track", method: "set_animation_keyframe", params: [{ name: "node_path", type: "string", required: true }, { name: "animation", type: "string", required: true }, { name: "track", type: "number" }, { name: "time", type: "number" }, { name: "value", type: "string" }] },
  { name: "get_animation_info", description: "Detailed animation info", method: "get_animation_info", params: [{ name: "node_path", type: "string", required: true }, { name: "animation", type: "string", required: true }] },
  { name: "remove_animation", description: "Remove an animation", method: "remove_animation", params: [{ name: "node_path", type: "string", required: true }, { name: "animation", type: "string", required: true }] },

  // TileMap (6)
  { name: "tilemap_set_cell", description: "Set a single tile cell", method: "tilemap_set_cell", params: [{ name: "node_path", type: "string", required: true }, { name: "x", type: "number" }, { name: "y", type: "number" }, { name: "source", type: "number" }, { name: "atlas_x", type: "number" }, { name: "atlas_y", type: "number" }] },
  { name: "tilemap_fill_rect", description: "Fill rectangular region with tiles", method: "tilemap_fill_rect", params: [{ name: "node_path", type: "string", required: true }, { name: "x", type: "number" }, { name: "y", type: "number" }, { name: "width", type: "number" }, { name: "height", type: "number" }] },
  { name: "tilemap_get_cell", description: "Get tile data at cell", method: "tilemap_get_cell", params: [{ name: "node_path", type: "string", required: true }, { name: "x", type: "number" }, { name: "y", type: "number" }] },
  { name: "tilemap_clear", description: "Clear all cells", method: "tilemap_clear", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "tilemap_get_info", description: "TileMapLayer info and tile set sources", method: "tilemap_get_info", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "tilemap_get_used_cells", description: "List of used cells", method: "tilemap_get_used_cells", params: [{ name: "node_path", type: "string", required: true }] },

  // Theme/UI (6)
  { name: "create_theme", description: "Create Theme resource file", method: "create_theme", params: [{ name: "theme_path", type: "string" }] },
  { name: "set_theme_color", description: "Set theme color override", method: "set_theme_color", params: [{ name: "node_path", type: "string", required: true }, { name: "name", type: "string" }, { name: "color", type: "string" }] },
  { name: "set_theme_constant", description: "Set theme constant override", method: "set_theme_constant", params: [{ name: "node_path", type: "string", required: true }, { name: "name", type: "string" }, { name: "value", type: "number" }] },
  { name: "set_theme_font_size", description: "Set theme font size override", method: "set_theme_font_size", params: [{ name: "node_path", type: "string", required: true }, { name: "name", type: "string" }, { name: "size", type: "number" }] },
  { name: "set_theme_stylebox", description: "Set StyleBoxFlat override", method: "set_theme_stylebox", params: [{ name: "node_path", type: "string", required: true }, { name: "name", type: "string" }, { name: "color", type: "string" }] },
  { name: "get_theme_info", description: "Get theme overrides info", method: "get_theme_info", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "setup_control", description: "Configure Control anchors, size flags and offsets", method: "setup_control", params: [{ name: "node_path", type: "string", required: true }, { name: "anchor_preset", type: "string" }, { name: "size_flags_horizontal", type: "number" }, { name: "size_flags_vertical", type: "number" }, { name: "text", type: "string" }] },

  // Profiling (2)
  { name: "get_performance_monitors", description: "All performance monitors", method: "get_performance_monitors" },
  { name: "get_editor_performance", description: "Quick performance summary", method: "get_editor_performance" },

  // Batch/Refactor (8)
  { name: "find_nodes_by_type", description: "Find all nodes of a type", method: "find_nodes_by_type", params: [{ name: "type", type: "string", required: true }] },
  { name: "find_signal_connections", description: "Find all signal connections in scene", method: "find_signal_connections" },
  { name: "batch_set_property", description: "Set property on all nodes of a type", method: "batch_set_property", params: [{ name: "type", type: "string", required: true }, { name: "property", type: "string", required: true }, { name: "value", type: "string", required: true }] },
  { name: "find_node_references", description: "Search project files for pattern", method: "find_node_references", params: [{ name: "pattern", type: "string", required: true }] },
  { name: "get_scene_dependencies", description: "Get resource dependencies", method: "get_scene_dependencies", params: [{ name: "scene_path", type: "string" }] },
  { name: "cross_scene_set_property", description: "Set property across all scenes", method: "cross_scene_set_property", params: [{ name: "directory", type: "string" }, { name: "type", type: "string", required: true }, { name: "property", type: "string", required: true }, { name: "value", type: "string", required: true }] },
  { name: "find_script_references", description: "Find where script/resource is used", method: "find_script_references", params: [{ name: "script_path", type: "string", required: true }] },
  { name: "detect_circular_dependencies", description: "Find circular scene dependencies", method: "detect_circular_dependencies", params: [{ name: "scene_path", type: "string" }] },
  { name: "batch_add_nodes", description: "Add multiple nodes in one operation", method: "batch_add_nodes", params: [{ name: "nodes", type: "array", required: true }] },

  // Shader (6)
  { name: "create_shader", description: "Create shader with template", method: "create_shader", params: [{ name: "shader_path", type: "string" }, { name: "type", type: "string" }, { name: "content", type: "string" }] },
  { name: "read_shader", description: "Read shader file", method: "read_shader", params: [{ name: "shader_path", type: "string", required: true }] },
  { name: "edit_shader", description: "Edit shader", method: "edit_shader", params: [{ name: "shader_path", type: "string", required: true }, { name: "content", type: "string" }, { name: "search", type: "string" }, { name: "replace", type: "string" }] },
  { name: "assign_shader_material", description: "Assign ShaderMaterial to node", method: "assign_shader_material", params: [{ name: "node_path", type: "string", required: true }, { name: "shader_path", type: "string", required: true }] },
  { name: "set_shader_param", description: "Set shader parameter", method: "set_shader_param", params: [{ name: "node_path", type: "string", required: true }, { name: "param", type: "string", required: true }, { name: "value", type: "string", required: true }] },
  { name: "get_shader_params", description: "Get all shader parameters", method: "get_shader_params", params: [{ name: "node_path", type: "string", required: true }] },

  // Export (3)
  { name: "list_export_presets", description: "List export presets", method: "list_export_presets" },
  { name: "export_project", description: "Get export command for preset", method: "export_project", params: [{ name: "preset", type: "string", required: true }, { name: "path", type: "string", required: true }] },
  { name: "get_export_info", description: "Export-related project info", method: "get_export_info" },

  // Resource (6)
  { name: "read_resource", description: "Read .tres resource properties", method: "read_resource", params: [{ name: "resource_path", type: "string", required: true }] },
  { name: "edit_resource", description: "Edit resource properties", method: "edit_resource", params: [{ name: "resource_path", type: "string", required: true }, { name: "properties", type: "record", required: true }] },
  { name: "create_resource", description: "Create new .tres resource", method: "create_resource", params: [{ name: "resource_path", type: "string", required: true }, { name: "type", type: "string" }] },
  { name: "get_resource_preview", description: "Get resource thumbnail", method: "get_resource_preview", params: [{ name: "resource_path", type: "string", required: true }] },
  { name: "add_autoload", description: "Register autoload singleton", method: "add_autoload", params: [{ name: "name", type: "string", required: true }, { name: "script_path", type: "string", required: true }] },
  { name: "remove_autoload", description: "Remove autoload singleton", method: "remove_autoload", params: [{ name: "name", type: "string", required: true }] },

  // Physics (6)
  { name: "setup_physics_body", description: "Configure physics body properties", method: "setup_physics_body", params: [{ name: "node_path", type: "string", required: true }, { name: "gravity_scale", type: "number" }, { name: "mass", type: "number" }] },
  { name: "setup_collision", description: "Add collision shapes to nodes", method: "setup_collision", params: [{ name: "node_path", type: "string", required: true }, { name: "shape_type", type: "string" }, { name: "width", type: "number" }, { name: "height", type: "number" }] },
  { name: "set_physics_layers", description: "Set collision layer/mask", method: "set_physics_layers", params: [{ name: "node_path", type: "string", required: true }, { name: "layer", type: "number" }, { name: "mask", type: "number" }] },
  { name: "get_physics_layers", description: "Get collision layer/mask info", method: "get_physics_layers", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "get_collision_info", description: "Get collision shape details", method: "get_collision_info", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "add_raycast", description: "Add RayCast2D/3D node", method: "add_raycast", params: [{ name: "parent_path", type: "string" }, { name: "is_3d", type: "boolean" }, { name: "name", type: "string" }] },

  // 3D Scene (6)
  { name: "add_mesh_instance", description: "Add MeshInstance3D with primitive mesh", method: "add_mesh_instance", params: [{ name: "parent_path", type: "string" }, { name: "primitive", type: "string" }, { name: "name", type: "string" }] },
  { name: "setup_camera_3d", description: "Configure Camera3D properties", method: "setup_camera_3d", params: [{ name: "node_path", type: "string", required: true }, { name: "fov", type: "number" }, { name: "x", type: "number" }, { name: "y", type: "number" }, { name: "z", type: "number" }] },
  { name: "setup_lighting", description: "Add/configure light nodes", method: "setup_lighting", params: [{ name: "parent_path", type: "string" }, { name: "type", type: "string" }, { name: "energy", type: "number" }] },
  { name: "setup_environment", description: "Configure WorldEnvironment", method: "setup_environment", params: [{ name: "parent_path", type: "string" }, { name: "background_color", type: "string" }] },
  { name: "add_gridmap", description: "Set up GridMap node", method: "add_gridmap", params: [{ name: "parent_path", type: "string" }, { name: "mesh_library", type: "string" }] },
  { name: "set_material_3d", description: "Set StandardMaterial3D properties", method: "set_material_3d", params: [{ name: "node_path", type: "string", required: true }, { name: "color", type: "string" }] },

  // Particle (5)
  { name: "create_particles", description: "Create GPUParticles2D/3D", method: "create_particles", params: [{ name: "parent_path", type: "string" }, { name: "is_3d", type: "boolean" }] },
  { name: "set_particle_material", description: "Configure ParticleProcessMaterial", method: "set_particle_material", params: [{ name: "node_path", type: "string", required: true }, { name: "spread", type: "number" }, { name: "velocity_min", type: "number" }, { name: "velocity_max", type: "number" }] },
  { name: "set_particle_color_gradient", description: "Set color gradient for particles", method: "set_particle_color_gradient", params: [{ name: "node_path", type: "string", required: true }, { name: "start_color", type: "string" }, { name: "end_color", type: "string" }] },
  { name: "apply_particle_preset", description: "Apply preset (fire, smoke, sparks)", method: "apply_particle_preset", params: [{ name: "node_path", type: "string", required: true }, { name: "preset", type: "string" }] },
  { name: "get_particle_info", description: "Get particle system details", method: "get_particle_info", params: [{ name: "node_path", type: "string", required: true }] },

  // Navigation (6)
  { name: "setup_navigation_region", description: "Configure NavigationRegion", method: "setup_navigation_region", params: [{ name: "parent_path", type: "string" }, { name: "is_3d", type: "boolean" }] },
  { name: "setup_navigation_agent", description: "Configure NavigationAgent", method: "setup_navigation_agent", params: [{ name: "parent_path", type: "string" }, { name: "is_3d", type: "boolean" }, { name: "max_speed", type: "number" }] },
  { name: "bake_navigation_mesh", description: "Bake navigation mesh", method: "bake_navigation_mesh", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "set_navigation_layers", description: "Set navigation layers", method: "set_navigation_layers", params: [{ name: "node_path", type: "string", required: true }, { name: "layers", type: "number" }] },
  { name: "get_navigation_info", description: "Get navigation setup info", method: "get_navigation_info", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "get_navigation_path", description: "Compute path between two points", method: "get_navigation_path", params: [{ name: "from_x", type: "number" }, { name: "from_y", type: "number" }, { name: "to_x", type: "number" }, { name: "to_y", type: "number" }] },

  // Audio (6)
  { name: "add_audio_player", description: "Add AudioStreamPlayer node", method: "add_audio_player", params: [{ name: "parent_path", type: "string" }, { name: "stream_path", type: "string" }, { name: "is_3d", type: "boolean" }] },
  { name: "add_audio_bus", description: "Add audio bus", method: "add_audio_bus", params: [{ name: "name", type: "string" }] },
  { name: "add_audio_bus_effect", description: "Add effect to audio bus", method: "add_audio_bus_effect", params: [{ name: "bus", type: "string" }, { name: "effect_type", type: "string" }] },
  { name: "set_audio_bus", description: "Configure audio bus properties", method: "set_audio_bus", params: [{ name: "bus", type: "string" }, { name: "volume_db", type: "number" }, { name: "mute", type: "boolean" }] },
  { name: "get_audio_bus_layout", description: "Get audio bus layout info", method: "get_audio_bus_layout" },
  { name: "get_audio_info", description: "Get audio-related node info", method: "get_audio_info", params: [{ name: "node_path", type: "string", required: true }] },

  // AnimationTree (8)
  { name: "create_animation_tree", description: "Create AnimationTree", method: "create_animation_tree", params: [{ name: "parent_path", type: "string" }, { name: "anim_player_path", type: "string" }] },
  { name: "get_animation_tree_structure", description: "Get tree structure", method: "get_animation_tree_structure", params: [{ name: "node_path", type: "string", required: true }] },
  { name: "set_tree_parameter", description: "Set AnimationTree parameter", method: "set_tree_parameter", params: [{ name: "node_path", type: "string", required: true }, { name: "parameter", type: "string", required: true }, { name: "value", type: "string", required: true }] },
  { name: "add_state_machine_state", description: "Add state to state machine", method: "add_state_machine_state", params: [{ name: "node_path", type: "string", required: true }, { name: "state_name", type: "string", required: true }, { name: "animation", type: "string" }] },
  { name: "remove_state_machine_state", description: "Remove state from state machine", method: "remove_state_machine_state", params: [{ name: "node_path", type: "string", required: true }, { name: "state_name", type: "string", required: true }] },
  { name: "add_state_machine_transition", description: "Add transition between states", method: "add_state_machine_transition", params: [{ name: "node_path", type: "string", required: true }, { name: "from", type: "string", required: true }, { name: "to", type: "string", required: true }] },
  { name: "remove_state_machine_transition", description: "Remove state transition", method: "remove_state_machine_transition", params: [{ name: "node_path", type: "string", required: true }, { name: "from", type: "string", required: true }, { name: "to", type: "string", required: true }] },
  { name: "set_blend_tree_node", description: "Configure blend tree nodes", method: "set_blend_tree_node", params: [{ name: "node_path", type: "string", required: true }] },

  // Analysis (4)
  { name: "analyze_scene_complexity", description: "Analyze scene performance", method: "analyze_scene_complexity" },
  { name: "analyze_signal_flow", description: "Map signal connections", method: "analyze_signal_flow" },
  { name: "find_unused_resources", description: "Find unreferenced resources", method: "find_unused_resources", params: [{ name: "directory", type: "string" }, { name: "max_results", type: "number" }] },
  { name: "get_project_statistics", description: "Get project-wide statistics", method: "get_project_statistics" },

  // Testing/QA (6)
  { name: "run_test_scenario", description: "Run automated test scenario", method: "run_test_scenario", params: [{ name: "steps", type: "array", required: true }] },
  { name: "assert_node_state", description: "Assert node property values", method: "assert_node_state", params: [{ name: "node_path", type: "string", required: true }, { name: "property", type: "string", required: true }, { name: "expected", type: "string", required: true }] },
  { name: "assert_screen_text", description: "Check for text on screen", method: "assert_screen_text", params: [{ name: "text", type: "string", required: true }] },
  { name: "run_stress_test", description: "Run performance stress test", method: "run_stress_test", params: [{ name: "duration", type: "number" }] },
  { name: "get_test_report", description: "Get test results report", method: "get_test_report" },

  // Android (3)
  { name: "list_android_devices", description: "List connected Android devices via adb", method: "list_android_devices" },
  { name: "deploy_to_android", description: "Export and deploy APK to device", method: "deploy_to_android", params: [{ name: "preset", type: "string" }, { name: "apk_path", type: "string" }] },
  { name: "get_android_build_info", description: "Get Android export settings", method: "get_android_build_info" },
  { name: "get_android_preset_info", description: "Get detailed Android export preset options", method: "get_android_preset_info", params: [{ name: "preset", type: "string" }] },
];
