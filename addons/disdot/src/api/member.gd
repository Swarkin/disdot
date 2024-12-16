class_name GuildMember
extends BetterBaseClass
## https://discord.com/developers/docs/resources/guild#guild-member-object

var user: User
var nick: String

func _init(d: Dictionary) -> void:
	user = User.new(_try_take(d, "user", {}) as Dictionary)
	nick = _try_take(d, "nick", "") as String
