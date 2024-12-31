extends Node
class_name Disdot

signal starting
signal stopping

# https://discord.com/developers/docs/events/gateway-events#receive-events
class EventType:
	const READY := "READY"
	const INVALID_SESSION := "INVALID_SESSION"
	const GUILD_CREATE := "GUILD_CREATE"
	const INTERACTION_CREATE := "INTERACTION_CREATE"
	const MESSAGE_CREATE := "MESSAGE_CREATE"

@export var bot_token: ValueContainer
@export var app_id: ValueContainer
@export var autostart := false
@export var verbose := false
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

var text_command_cache: Dictionary[String, TextCommandHandler]
var slash_command_cache: Dictionary[String, SlashCommandHandler]
var event_cache: Dictionary[String, BaseEventHandler]

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
		print("Starting...")
		print("Token: ", bot_token.get_value())
		print("App ID: ", app_id.get_value())
		print("Text Commands: ", text_command_cache)
		print("Slash Commands: ", slash_command_cache)
		print("Events: ", event_cache)

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
func stop(clean := true) -> void:
	if _socket.s.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		push_error("Websocket is not connected")
		return

	if verbose: print("Stopping...")
	stopping.emit()

	_heartbeat_timer.stop()
	_socket.close_connection(1000 if clean else 1002)


# https://discord.com/developers/docs/events/gateway-events
func _on_packet_received(p: PackedByteArray) -> void:
	var packet_str := p.get_string_from_utf8()
	var json := JSON.parse_string(packet_str)
	if typeof(json) != TYPE_DICTIONARY:
		push_error("Invalid packet received")
		if verbose: print(packet_str)
		stop(false)
		return

	var payload := Payload.new(json as Dictionary)

	match payload.op:
		Payload.Op.DISPATCH:
			_update_seq(payload.s.value)
			var event: Event
			var event_name := payload.t.value
			if verbose: print(event_name)

			match event_name:
				EventType.READY:
					event = ReadyEvent.new(payload.d)

				EventType.INVALID_SESSION:
					event = InvalidSessionEvent.new(payload.d as bool)
					push_error("Invalid Session event received")
					# TODO: resume connection

					stop()
					return

				EventType.GUILD_CREATE:
					event = GuildCreateEvent.new(payload.d)

				EventType.INTERACTION_CREATE:
					event = InteractionCreateEvent.new(payload.d, _api)

				EventType.MESSAGE_CREATE:
					event = MessageCreateEvent.new(payload.d, _api)
					_dispatch_text_command(event)

				_:
					push_warning("Event not implemented: ", event_name)
					return

			_dispatch_event(event_name.to_snake_case().to_upper(), event)

		Payload.Op.HELLO:
			var interval_s := (payload.d["heartbeat_interval"] as float) * 0.001
			if interval_s < 10.0:
				push_error("Unexpected heartbeat interval: ", interval_s, "s")
				stop(false)
				return

			if verbose: print("Heartbeat interval: ", interval_s, "s")

			_heartbeat()
			_identify()

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
	if verbose: print("Identify with Intents: ", intents)

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
	text_command_cache.clear()
	var commands := get_node_or_null(^"Commands")
	if !commands: return

	for node in commands.get_children():
		if node is TextCommandHandler or node is SlashCommandHandler:
			_cache_command(node)
		elif node is BaseCommandHandler && verbose:
			push_warning("Unknown CommandHandler node: ", node.get_path())

func update_events() -> void:
	event_cache.clear()
	var events_node := get_node_or_null(^"Events")
	if !events_node: return

	for node in events_node.get_children():
		if node is BaseEventHandler:
			var event := node as BaseEventHandler
			var event_name := event.name.to_snake_case().to_upper()
			if !event_name in EventType:
				push_warning("Invalid Event "+event_name)
				continue

			if verbose: print("Adding Event "+event_name)
			event_cache[event_name] = event

func _cache_command(cmd: BaseCommandHandler) -> void:
	if cmd is TextCommandHandler:
		text_command_cache[cmd.name] = cmd
		if verbose: print("Registering TextCommandHandler for '", cmd.name, "'")
	elif cmd is SlashCommandHandler:
		slash_command_cache[cmd.name] = cmd
		if verbose: print("Registering SlashCommandHandler for '", cmd.name, "'")
	else:
		push_error("Invalid CommandHandler")


func _dispatch_text_command(event: MessageCreateEvent) -> void:
	for prefix in text_command_cache:
		if event.message.content.begins_with(prefix):
			var command_handler := text_command_cache[prefix]
			if command_handler.ignore_bots && event.message.author.bot:
				break

			command_handler._on_command(TextCommandContext.new(_api, event.message))
			break

func _dispatch_event(event_name: String, data: Event) -> void:
	if !event_cache.has(event_name):
		if verbose: print("No handler for event '", event_name, "'")
		return

	event_cache[event_name]._on_event(data)
