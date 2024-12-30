extends Node
class_name Disdot

signal starting
signal stopping

class EventType:
	const READY := "READY"
	const MESSAGE_CREATE := "MESSAGE_CREATE"
	const GUILD_CREATE := "GUILD_CREATE"
	const INTERACTION_CREATE := "INTERACTION_CREATE"

@export var bot_token: ValueContainer
@export var app_id: ValueContainer
@export var autostart := false
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
	"DIRECT_MESSAGE_POLLS:33554432",
) var intents: int

var _api: DiscordAPI
var _socket: BetterWebsocket
var _heartbeat_timer: Timer

var _socket_url: String
var _last_seq: int

var command_cache: Dictionary[String, Array]  # Array[CommandHandler]
var event_cache: Dictionary[String, EventHandler]

func _ready() -> void:
	_api = DiscordAPI.new()
	_api.token = bot_token
	_api.app_id = app_id

	_socket = BetterWebsocket.new()
	if verbose: _socket.verbose = true
	_socket.packet_received.connect(_on_packet_received)

	_heartbeat_timer = Timer.new()
	_heartbeat_timer.timeout.connect(_heartbeat)

	for n in [_api, _socket, _heartbeat_timer] as Array[Node]:
		add_child(n)

	if autostart:
		start()


## Starts the Websocket connection. Returns false if any error was encountered.
func start() -> bool:
	if _socket.s.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		push_error("Websocket is in use")
		return false

	if bot_token.get_value().is_empty():
		push_error("Bot token missing")
		return false

	if app_id.get_value().is_empty():
		push_error("App ID missing")
		return false

	update_commands()
	update_events()

	if verbose:
		print("Token: "+bot_token.get_value())
		print("App ID: "+str(app_id.get_value()))
		print("Commands: "+str(command_cache))
		print("Events: "+str(event_cache))
		print("Starting...")

	starting.emit()

	var r := await _api.get_gateway_bot()
	if !r.success() or !r.status_ok():
		push_error("GET /gateway/bot failed")
		if verbose: print(r.body_as_string())
		return false

	var json := r.body_as_json()
	if json is not Dictionary:
		push_error("Invalid /gateway/bot response")
		if verbose: print(json)
		return false

	var url_base := (json as Dictionary).get("url", "") as String
	if url_base.is_empty():
		push_error("Invalid /gateway/bot response json" + (": "+str(json)) if verbose else "")
		if verbose: print(json)
		return false

	_socket_url = url_base + "/?v=10&encoding=json"
	if verbose: print("Websocket URL: ", _socket_url)

	var err := _socket.begin_connection(_socket_url)
	if err:
		push_error("Failed to start Websocket connection: ", error_string(err))
		return false

	return true


## Stops the Websocket connection and resets related internal state.
func stop() -> void:
	if _socket.s.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		push_error("Websocket is not connected")
		return

	if verbose: print("Stopping...")
	stopping.emit()

	_heartbeat_timer.stop()
	_socket.close_connection()


# https://discord.com/developers/docs/events/gateway-events
func _on_packet_received(p: PackedByteArray) -> void:
	var packet_str := p.get_string_from_utf8()
	var json := JSON.parse_string(packet_str)
	if typeof(json) != TYPE_DICTIONARY:
		push_error("Invalid packet received")
		if verbose: print(packet_str)
		stop()
		return

	var payload := Payload.new(json as Dictionary)

	match payload.op:
		Payload.Op.DISPATCH:
			_update_seq(payload.s.value)
			if verbose: print(payload.t)
			var event: Event

			match payload.t:
				EventType.READY:
					event = ReadyEvent.new(payload.d)

				EventType.MESSAGE_CREATE:
					event = MessageCreateEvent.new(payload.d, _api)
					for prefix in command_cache.keys() as Array[String]:
						if event.message.content.begins_with(prefix):
							for cmd in command_cache[prefix] as Array[CommandHandler]:
								if cmd.ignore_bots and event.message.author.bot:
									continue

								if event.message.content.begins_with(prefix+cmd.name):
									_dispatch_command(cmd.name, prefix, CommandContext.new(_api, event.message))

				EventType.GUILD_CREATE:
					event = GuildCreateEvent.new(payload.d)

				EventType.INTERACTION_CREATE:
					event = InteractionCreateEvent.new(payload.d, _api)

				_: return

			_dispatch_event(payload.t.to_snake_case().to_upper(), event)

		Payload.Op.HELLO:
			var interval_s := (payload.d["heartbeat_interval"] as float) * 0.001
			assert(interval_s > 10.0, "Unexpected heartbeat interval")

			_heartbeat()
			_identify()

			if verbose: print("Starting heartbeat Timer with an interval of ", interval_s, "s")
			_heartbeat_timer.start(interval_s)

		Payload.Op.HEARTBEAT_ACK:
			# TODO: handle zombied connections
			pass

		_:
			if verbose: print("Unhandled Opcode: ", payload.op)

# https://discord.com/developers/docs/events/gateway-events#heartbeat
func _heartbeat() -> void:
	if verbose: print("Heartbeat")

	_socket.send_packet(JSON.stringify(
		{"op": Payload.Op.HEARTBEAT as int, "d": _last_seq if _last_seq else null}
	))

# https://discord.com/developers/docs/events/gateway-events#identify
func _identify() -> void:
	if verbose: print("Identify with intents ", intents)

	_socket.send_packet(JSON.stringify({
		"op": Payload.Op.IDENTIFY as int,
		"d": {
			"token": bot_token.get_value(),
			"intents": intents,
			"properties": {
				"os": "linux",
				"browser": "disdot",
				"device": "disdot"
			},
		}
	}))

func _update_seq(num: int) -> void:
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
		EventType.INTERACTION_CREATE:
			(event_cache[event_name] as InteractionCreateEventHandler)._on_event(data)
		_:
			push_warning("Invalid or unimplemented event: ", event_name)
