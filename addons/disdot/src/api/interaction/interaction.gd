class_name Interaction
extends BetterBaseClass
##[url]https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object[/url]

enum Type {
	PING = 1,
	APPLICATION_COMMAND = 2,
	MESSAGE_COMPONENT = 3,
	APPLICATION_COMMAND_AUTOCOMPLETE = 4,
	MODAL_SUBMIT = 5,
}

enum ContextType {
	GUILD = 0,
	BOT_DM = 1,
	PRIVATE_CHANNEL = 2,
	UNKNOWN = 3,
}

var _api: DiscordAPI
var id: int
var application_id: int
var type: Type
var data: BaseInteractionData
var guild: Guild  # Partial Guild object
var guild_id: int
var channel: Channel  # Partial Channel object
var channel_id: int
var member: GuildMember
var token: String  # Continuation token for responding to the interaction
# ...
var context: ContextType

func _init(d: Dictionary, api: DiscordAPI) -> void:
	_api = api
	id = _take_int(d, "id")
	application_id = _take_int(d, "application_id")
	type = _take_int(d, "type") as Type
	var _data := _try_dict(d, "data", {})
	match type:
		Type.PING:
			data = null
		Type.APPLICATION_COMMAND:
			data = ApplicationCommandInteractionData.new(_data)
		_:
			push_warning("Interaction data type '", str(type), "' unsupported")
	guild = Guild.new(_try_dict(d, "guild", {}))
	guild_id = _try_str(d, "guild_id", "").to_int()
	channel = Channel.new(_try_dict(d, "channel", {}), api)
	channel_id = _try_str(d, "channel_id", "").to_int()
	member = GuildMember.new(_try_dict(d, "member", {}))
	token = _take_str(d, "token")
	context = _try_int(d, "context", ContextType.UNKNOWN) as ContextType

func respond(content: String, tts := false) -> void:
	var interaction_response := InteractionResponse.new(
		InteractionResponse.CallbackType.CHANNEL_MESSAGE_WITH_SOURCE,
		MessageInteractionCallbackData.new(content, tts)
	)
	var result := await _api.create_interaction_response(id, token, interaction_response)
	print("uwuwuwu")
	print("uwuwu")
	print("uwu")
	print(result.status)
	print(result.body_as_string())
	print("uwu")
	print("uwuwu")
	print("uwuwuwu")
