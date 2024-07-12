extends RefCounted
class_name MessageReference

## [url]https://discord.com/developers/docs/resources/channel#message-reference-object[/url]

func _init() -> void:
	pass

static func from_dict(d: Dictionary) -> MessageReference:
	var v := MessageReference.new()
	if d.has("message_id"): v.message_id = Int.new(BetterBaseClass._take_int(d, "message_id"))
	if d.has("channel_id"): v.channel_id = Int.new(BetterBaseClass._take_int(d, "channel_id"))
	if d.has("guild_id"  ): v.guild_id   = Int.new(BetterBaseClass._take_int(d, "guild_id"  ))
	if d.has("fail_if_not_exists"): v.fail_if_not_exists = Bool.new(BetterBaseClass._take_bool(d, "fail_if_not_exists"))
	return v

static func reply(message_id: int) -> MessageReference:
	var v := MessageReference.new()
	v.message_id = Int.new(message_id)
	return v

var message_id: Int
var channel_id: Int
var guild_id: Int
var fail_if_not_exists: Bool

func to_dict() -> Dictionary:
	var data := {}
	if message_id: data["message_id"] = str(message_id)
	if channel_id: data["channel_id"] = str(channel_id)
	if guild_id  : data["guild_id"  ] = str(guild_id  )
	if fail_if_not_exists: data["fail_if_not_exists"] = str(fail_if_not_exists)
	return data
