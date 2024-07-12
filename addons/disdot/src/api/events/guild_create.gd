class_name GuildCreateEvent
extends Event
## [url]https://discord.com/developers/docs/topics/gateway-events#guild-create[/url]

var id: int
var name: String

func _init(d: Dictionary) -> void:
	id =   _try_take(d, "id"  , 0 ) as int
	name = _try_take(d, "name", "") as String
