@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"create_animation_tree": _create_animation_tree,
		"get_animation_tree_structure": _get_animation_tree_structure,
		"set_tree_parameter": _set_tree_parameter,
		"add_state_machine_state": _add_state_machine_state,
		"remove_state_machine_state": _remove_state_machine_state,
		"add_state_machine_transition": _add_state_machine_transition,
		"remove_state_machine_transition": _remove_state_machine_transition,
		"set_blend_tree_node": _set_blend_tree_node,
	}


func _get_tree(path: String) -> AnimationTree:
	var node := _resolve_node(path)
	return node if node is AnimationTree else null


func _create_animation_tree(p: Dictionary) -> Dictionary:
	var parent := _resolve_node(p.get("parent_path", "."))
	if parent == null:
		return _err("Parent not found")
	var tree := AnimationTree.new()
	tree.name = p.get("name", "AnimationTree")
	var player_path: String = p.get("anim_player_path", "")
	if not player_path.is_empty():
		tree.anim_player = NodePath(player_path)
	parent.add_child(tree, true)
	tree.owner = _edited_root()
	return _ok({"path": str(tree.get_path())})


func _get_animation_tree_structure(p: Dictionary) -> Dictionary:
	var tree := _get_tree(p.get("node_path", ""))
	if tree == null:
		return _err("AnimationTree not found")
	return _ok({
		"active": tree.active,
		"tree_root": str(tree.tree_root) if tree.tree_root else "",
		"parameters": tree.get_parameter_list(),
	})


func _set_tree_parameter(p: Dictionary) -> Dictionary:
	var tree := _get_tree(p.get("node_path", ""))
	if tree == null:
		return _err("AnimationTree not found")
	var param: String = p.get("parameter", "")
	tree.set(param, _parse_value(str(p.get("value", "0"))))
	return _ok({"parameter": param})


func _add_state_machine_state(p: Dictionary) -> Dictionary:
	var tree := _get_tree(p.get("node_path", ""))
	if tree == null or tree.tree_root == null:
		return _err("AnimationTree with tree_root required")
	var sm: AnimationNodeStateMachine = tree.tree_root
	var state_name: String = p.get("state_name", "NewState")
	var anim_node := AnimationNodeAnimation.new()
	var anim_name: String = p.get("animation", "")
	if not anim_name.is_empty():
		anim_node.animation = anim_name
	sm.add_node(state_name, anim_node)
	return _ok({"state": state_name})


func _remove_state_machine_state(p: Dictionary) -> Dictionary:
	var tree := _get_tree(p.get("node_path", ""))
	if tree == null or tree.tree_root == null:
		return _err("AnimationTree required")
	var sm: AnimationNodeStateMachine = tree.tree_root
	sm.remove_node(p.get("state_name", ""))
	return _ok({"removed": p.get("state_name", "")})


func _add_state_machine_transition(p: Dictionary) -> Dictionary:
	var tree := _get_tree(p.get("node_path", ""))
	if tree == null or tree.tree_root == null:
		return _err("AnimationTree required")
	var sm: AnimationNodeStateMachine = tree.tree_root
	var from_state: String = p.get("from", "")
	var to_state: String = p.get("to", "")
	sm.add_transition(from_state, to_state, AnimationNodeStateMachineTransition.new())
	return _ok({"from": from_state, "to": to_state})


func _remove_state_machine_transition(p: Dictionary) -> Dictionary:
	var tree := _get_tree(p.get("node_path", ""))
	if tree == null or tree.tree_root == null:
		return _err("AnimationTree required")
	var sm: AnimationNodeStateMachine = tree.tree_root
	sm.remove_transition(p.get("from", ""), p.get("to", ""))
	return _ok({"removed": true})


func _set_blend_tree_node(p: Dictionary) -> Dictionary:
	var tree := _get_tree(p.get("node_path", ""))
	if tree == null:
		return _err("AnimationTree not found")
	var blend := AnimationNodeBlendTree.new()
	tree.tree_root = blend
	return _ok({"blend_tree": true, "note": "Created new BlendTree root"})
