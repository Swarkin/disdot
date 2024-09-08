class_name Message
extends BetterBaseClass

var _api: DiscordAPI
var id: int
var channel_id: int
var content: String
var author: User

func _init(d: Dictionary, api: DiscordAPI) -> void:
	_api = api
	id         = _try_take(d, "id"        , 0 ) as int
	channel_id = _try_take(d, "channel_id", 0 ) as int
	content    = _try_take(d, "content"   , "") as String
	author     = User.new(_try_take(d, "author" , {}) as Dictionary)

func reply(content: String) -> void:
	await _api.create_message(channel_id, content, MessageReference.reply(id))


func get_channel() -> Channel:
	var resp := await _api.get_channel(channel_id)
	if resp.success() && resp.status_ok():
		return Channel.new(resp.body_as_json() as Dictionary, _api)

	return null
