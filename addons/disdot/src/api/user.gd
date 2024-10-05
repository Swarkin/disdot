class_name User
extends BetterBaseClass
## https://discord.com/developers/docs/resources/user

func _init(d: Dictionary) -> void:
	id          = _try_take(d, "id"         , 0 ) as int
	username    = _try_take(d, "username"   , "") as String
	global_name = _try_take(d, "global_name", "") as String
	bot         = _try_take(d, "bot"        , false) as bool

## the user's id
var id: int
## the user's username, not unique across the platform
var username: String
## the user's display name, if it is set. For bots, this is the application name
var global_name: String
## whether the user belongs to an OAuth2 application
var bot: bool
