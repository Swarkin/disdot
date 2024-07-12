class_name Message
extends BetterBaseClass

func _init(d: Dictionary) -> void:
	id         = _try_take(d, "id"        , 0 ) as int
	channel_id = _try_take(d, "channel_id", 0 ) as int
	content    = _try_take(d, "content"   , "") as String
	author     = User.new(_try_take(d, "author" , {}) as Dictionary)

var id: int
var channel_id: int
var content: String
var author: User
