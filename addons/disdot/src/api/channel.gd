class_name Channel
extends BetterBaseClass
## [url]https://discord.com/developers/docs/resources/channel[/url]

var _api: DiscordAPI
var id: int

func _init(d: Dictionary, api: DiscordAPI) -> void:
	_api = api
	id   = _try_take(d, "id", 0) as int

func send(content: String) -> void:
	await _api.create_message(id, content)
