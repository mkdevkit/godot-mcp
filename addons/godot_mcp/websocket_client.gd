@tool
extends Node

## WebSocket client that connects to the Node.js MCP server.
## Godot plugin acts as client; MCP server hosts the WebSocket endpoint.

signal connected()
signal disconnected()

var command_router: Node

const DEFAULT_PORT := 6505
const RECONNECT_BASE_SEC := 1.0
const RECONNECT_MAX_SEC := 60.0
const PING_INTERVAL_SEC := 10.0
const BUFFER_SIZE := 8 * 1024 * 1024

var _port: int = DEFAULT_PORT
var _peer: WebSocketPeer
var _is_connected := false
var _reconnect_delay := RECONNECT_BASE_SEC
var _reconnect_timer := 0.0
var _ping_timer := 0.0
var _running := false

func get_port() -> int:
	return _port


func start() -> void:
	_running = true
	_port = int(OS.get_environment("GODOT_MCP_PORT") if OS.has_environment("GODOT_MCP_PORT") else DEFAULT_PORT)
	_try_connect()


func stop() -> void:
	_running = false
	if _peer:
		_peer.close(1000, "Plugin shutting down")
	_peer = null
	_is_connected = false


func _process(delta: float) -> void:
	if not _running:
		return

	if _peer == null:
		_reconnect_timer += delta
		if _reconnect_timer >= _reconnect_delay:
			_reconnect_timer = 0.0
			_try_connect()
		return

	_peer.poll()
	var state := _peer.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not _is_connected:
				_is_connected = true
				_reconnect_delay = RECONNECT_BASE_SEC
				_ping_timer = 0.0
				print("[Godot MCP] Connected to MCP server (ws://127.0.0.1:%d)" % _port)
				connected.emit()
			_ping_timer += delta
			if _ping_timer >= PING_INTERVAL_SEC:
				_ping_timer = 0.0
				_send_json({"jsonrpc": "2.0", "method": "ping", "params": {}})
			while _peer.get_available_packet_count() > 0:
				var text := _peer.get_packet().get_string_from_utf8()
				_handle_message(text)
		WebSocketPeer.STATE_CLOSED:
			if _is_connected:
				_is_connected = false
				disconnected.emit()
				print("[Godot MCP] Disconnected from MCP server")
			_peer = null
			_schedule_reconnect()
		WebSocketPeer.STATE_CLOSING, WebSocketPeer.STATE_CONNECTING:
			pass


func _try_connect() -> void:
	var ws := WebSocketPeer.new()
	ws.outbound_buffer_size = BUFFER_SIZE
	ws.inbound_buffer_size = BUFFER_SIZE
	var err := ws.connect_to_url("ws://127.0.0.1:%d" % _port)
	if err == OK:
		_peer = ws
	else:
		_peer = null
		_schedule_reconnect()


func _schedule_reconnect() -> void:
	_reconnect_timer = 0.0
	_reconnect_delay = minf(_reconnect_delay * 2.0, RECONNECT_MAX_SEC)


func _handle_message(text: String) -> void:
	var json := JSON.new()
	if json.parse(text) != OK:
		_send_error(null, -32700, "Parse error")
		return

	var msg: Variant = json.data
	if not msg is Dictionary:
		_send_error(null, -32600, "Invalid request")
		return

	var msg_dict: Dictionary = msg
	var method: String = msg_dict.get("method", "")

	if method == "ping":
		_send_json({"jsonrpc": "2.0", "method": "pong", "params": {}})
		return
	if method == "pong":
		return

	var id: Variant = msg_dict.get("id")
	var params: Dictionary = msg_dict.get("params", {})

	if method.is_empty():
		_send_error(id, -32600, "Missing method")
		return
	if not command_router:
		_send_error(id, -32603, "Command router not available")
		return

	_execute_command.call_deferred(id, method, params)


func _execute_command(id: Variant, method: String, params: Dictionary) -> void:
	var result: Dictionary = await command_router.execute(method, params)
	if result.has("error"):
		_send_response(id, null, result["error"])
	else:
		_send_response(id, result.get("result", {}), null)


func _send_response(id: Variant, result: Variant, err: Variant) -> void:
	var response := {"jsonrpc": "2.0", "id": id}
	if err != null:
		response["error"] = err
	else:
		response["result"] = result if result != null else {}
	_send_json(response)


func _send_error(id: Variant, code: int, message: String) -> void:
	_send_response(id, null, {"code": code, "message": message})


func _send_json(data: Dictionary) -> void:
	if _peer and _is_connected:
		_peer.send_text(JSON.stringify(data))
