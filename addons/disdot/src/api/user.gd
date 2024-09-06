class_name User
extends BetterBaseClass

func _init(d: Dictionary) -> void:
	id          = _try_take(d, "id"         , 0 ) as int
	username    = _try_take(d, "username"   , "") as String
	global_name = _try_take(d, "global_name", "") as String
	bot         = _try_take(d, "bot"        , false) as bool

var id: int
var username: String
var global_name: String
var bot: bool
