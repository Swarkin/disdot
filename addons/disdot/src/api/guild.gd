class_name Guild
extends BetterBaseClass
## https://discord.com/developers/docs/resources/guild#guild-member-object

var id: int
var name: String

func _init(d: Dictionary) -> void:
	id = _try_take(d, "id", 0) as int
	name = _try_take(d, "name", "") as String
