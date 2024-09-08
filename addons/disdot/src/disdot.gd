extends Node
class_name Disdot

enum Op {
	INVALID = -1,
	DISPATCH = 0,
	HEARTBEAT = 1,
	IDENTIFY = 2,
	PRESENCE_UPDATE = 3,
	VOICE_STATE_UPDATE = 4,
	RESUME = 6,
	RECONNECT = 7,
	REQUEST_GUILD_MEMBERS = 8,
	INVALID_SESSION = 9,
	HELLO = 10,
	HEARTBEAT_ACK = 11 }
class EventType:
	const READY := "READY"
	const MESSAGE_CREATE := "MESSAGE_CREATE"
	const GUILD_CREATE := "GUILD_CREATE"

@export var bot_token: ValueContainer
@export var app_id: ValueContainer
@export var verbose := true
@export_flags(
	"GUILDS:1",
	"GUILD_MEMBERS:2",
	"GUILD_MODERATION:4",
	"GUILD_EMOJIS_AND_STICKERS:8",
	"GUILD_INTEGRATIONS:16",
	"GUILD_WEBHOOKS:32",
	"GUILD_INVITES:64",
	"GUILD_VOICE_STATES:128",
	"GUILD_PRESENCES:256",
	"GUILD_MESSAGES:512",
	"GUILD_MESSAGE_REACTIONS:1024",
	"GUILD_MESSAGE_TYPING:2048",
	"DIRECT_MESSAGES:4096",
	"DIRECT_MESSAGE_REACTIONS:8192",
	"DIRECT_MESSAGE_TYPING:16384",
	"MESSAGE_CONTENT:32768",
	"GUILD_SCHEDULED_EVENTS:65536",
	"AUTO_MODERATION_CONFIGURATION:1048576",
	"AUTO_MODERATION_EXECUTION:2097152",
	"GUILD_MESSAGE_POLLS:16777216",
	"DIRECT_MESSAGE_POLLS:33554432"
) var intents: int

var _api: DiscordAPI
var _http: AwaitableHTTPRequest
var _socket: BetterWebsocket
var _heartbeat_timer: Timer

var _socket_url: String
var _last_seq: int

var command_cache: Dictionary #[prefix: String, commands: Array[CommandHandler]]
var event_cache: Dictionary #[name: String, event: EventHandler]

func _ready() -> void:
	assert(!bot_token.get_value().is_empty(), "Bot Token missing")
	assert(!app_id.get_value().is_empty(), "App ID missing")

	_api = DiscordAPI.new()
	_api.token = bot_token
	_api.app_id = app_id

	_http = AwaitableHTTPRequest.new()
	_http.accept_gzip = false
	_http.timeout = 8.0

	_socket = BetterWebsocket.new()
	_socket.verbose = true
	_socket.packet_received.connect(_on_packet_received)

	_heartbeat_timer = Timer.new()
	_heartbeat_timer.timeout.connect(_heartbeat)

	for n in [_api, _http, _socket, _heartbeat_timer] as Array[Node]:
		add_child(n)

	update_commands()
	update_events()

	if verbose:
		print("Token: "+bot_token.get_value())
		print("App ID: "+str(app_id.get_value()))
		print("Commands: "+str(command_cache))
		print("Events: "+str(event_cache))
		print("\nStarting...")

	var r := await _api.get_gateway_bot()
	assert(r.success() and r.status_ok(), "GET /gateway/bot failed")

	var json := r.body_as_json()
	assert(json)
	_socket_url = (json as Dictionary).get("url") as String + "/?v=10&encoding=json"
	if verbose: print("Websocket URL: ", _socket_url)

	_socket.begin_connection(_socket_url)


func stop() -> void:
	if verbose: print("Stopping...")

	_heartbeat_timer.stop()
	_socket.close_connection()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		stop()


func _on_packet_received(p: PackedByteArray) -> void:
	var packet_str := p.get_string_from_utf8()
	assert(!packet_str.is_empty())
	if verbose: print_rich("[color=gray]>>> ", packet_str, "[/color]")

	var json := JSON.parse_string(packet_str) as Dictionary
	_strip_packet_recursive(json, "_trace")

	var op := json.get("op", -1) as Op
	assert(op != -1)

	match op:
		Op.DISPATCH:
			_update_seq(json.get("s"))

			var event_data := json.get("d") as Dictionary
			var event_name := json.get("t") as String

			if verbose: print("--- Event ", event_name, "\n", event_data)

			var event: Event

			match event_name:
				EventType.READY:
					event = ReadyEvent.new(event_data)

				EventType.MESSAGE_CREATE:
					event = MessageCreateEvent.new(event_data, _api)
					for prefix in command_cache.keys() as Array[String]:
						if event.message.content.begins_with(prefix):
							for cmd in command_cache[prefix] as Array[CommandHandler]:
								if event.message.content.begins_with(prefix+cmd.name):
									_dispatch_command(cmd.name, prefix, CommandContext.new(_api, event.message))

				EventType.GUILD_CREATE:
					event = GuildCreateEvent.new(event_data)

				_:
					if verbose: print("--- Unhandled\n")
					return

			_dispatch_event(event_name.to_snake_case().to_upper(), event)

		Op.HELLO:
			if verbose: print("Hello Opcode received")
			var d := json.get("d") as Dictionary

			var interval_s := (d.get("heartbeat_interval") as float) * 0.001
			assert(interval_s > 10.0, "Heartbeat interval likely too low")

			_heartbeat()
			_identify()

			if verbose: print("Starting Heartbeat Timer with interval ", interval_s, "s")
			_heartbeat_timer.start(interval_s)

		Op.HEARTBEAT_ACK:
			if verbose: print_rich("[color=gray]>>> Heartbeat ACK[/color]")

		_:
			if verbose: print("Unhandled Opcode: ", op)

func _heartbeat() -> void:
	if verbose: print_rich("Heartbeat")

	_socket.send_packet(JSON.stringify(
		{"op": Op.HEARTBEAT, "d": _last_seq if _last_seq else null}
	))

func _identify() -> void:
	if verbose: print("Identify with intents ", intents)

	_socket.send_packet(JSON.stringify({
		"op": Op.IDENTIFY,
		"d": {
			"token": bot_token.get_value(),
			"intents": intents,
			"properties": {
				"os": "linux",
				"browser": "disdot",
				"device": "disdot"
			}
		}
	}))

func _update_seq(num: Variant) -> void:
	if num is int:
		if not _last_seq + 1 == num:
			push_warning("Missed a sequence number!")

		_last_seq = num
		if verbose: print_rich("[color=gray]Sequence number: ", num, "[/color]")


func update_commands() -> void:
	command_cache.clear()
	var cmds_node := get_node_or_null(^"Commands")
	if !cmds_node: return

	for node in cmds_node.get_children():
		if node is CommandHandler:
			var command := node as CommandHandler
			_cache_command(command)

		elif node is CommandGroup:
			var cmd_group := node as CommandGroup
			for cmd in cmd_group.get_children():
				if cmd is CommandHandler:
					var command := cmd as CommandHandler
					_cache_command(command, cmd_group.prefix)

func update_events() -> void:
	event_cache.clear()
	var events_node := get_node_or_null(^"Events")
	if !events_node:
		if verbose: print("No Events to update")
		return

	for node in events_node.get_children():
		if node is EventHandler:
			var event := node as EventHandler
			var event_name := event.name.to_snake_case().to_upper()
			if !event_name in EventType:
				push_warning("Invalid Event "+event_name)
				continue

			if verbose: print("Adding Event "+event_name)
			event_cache[event_name] = event

func _cache_command(cmd: CommandHandler, prefix := "") -> void:
	if prefix.is_empty():
		prefix = cmd.prefix

	if command_cache.has(prefix):
		(command_cache[prefix] as Array[CommandHandler]).append(cmd)
		if verbose: print("Adding Command ", cmd.name)
	else:
		command_cache[prefix] = [cmd] as Array[CommandHandler]
		if verbose: print("Adding Command ", cmd.name)


func _dispatch_command(cmd_name: String, prefix: String, ctx: CommandContext) -> void:
	if !command_cache.has(prefix):
		if verbose: print("No handler for command ", cmd_name)
		return

	for handler in command_cache[prefix] as Array[CommandHandler]:
		if handler.name == cmd_name:
			handler._on_command(ctx)
			break

func _dispatch_event(event_name: String, data: Event) -> void:
	if !event_cache.has(event_name):
		if verbose: print("No handler for event ", event_name)
		return

	match event_name:
		EventType.READY:
			(event_cache[event_name] as ReadyEventHandler)._on_event(data)
		EventType.MESSAGE_CREATE:
			(event_cache[event_name] as MessageCreateEventHandler)._on_event(data)
		_:
			push_warning("Invalid or unhandled Event "+event_name)


func _strip_packet_recursive(d: Dictionary, rm_key: String) -> void:
	d.erase(rm_key)

	for key in d.keys() as Array[String]:
		var val := d[key] as Variant

		if val is Dictionary:
			_strip_packet_recursive(val as Dictionary, rm_key)
		elif val is Array:
			_walk_array(val as Array, rm_key)

func _walk_array(arr: Array, rm_key: String) -> void:
	for val: Variant in arr:
		if val is Dictionary:
			_strip_packet_recursive(val as Dictionary, rm_key)
		elif val is Array:
			_walk_array(val as Array, rm_key)
