class_name ApplicationCommand
extends BetterBaseClass
## [url]https://discord.com/developers/docs/interactions/application-commands#application-command-object[/url]

enum Type {
	CHAT_INPUT = 1,
	USER = 2,
	MESSAGE = 3,
	PRIMARY_ENTRY_POINT = 4,
}

var _api: DiscordAPI
var id: int
var type: Type
var application_id: int
var guild_id: Int
var name: String
var description: String

func _init(d: Dictionary, api: DiscordAPI) -> void:
	_api = api
	id   = _try_take(d, "id", 0) as int
	type = _try_take(d, "type", Type.CHAT_INPUT) as int
