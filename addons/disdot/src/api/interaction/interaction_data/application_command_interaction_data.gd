class_name ApplicationCommandInteractionData
extends BaseInteractionData
## https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-application-command-data-structure

var id: int
var name: String
var type: int
#var resolved
var options: Array[ApplicationCommandInteractionDataOption]
var guild_id: int
var target_id: int

func _init(d: Dictionary) -> void:
	id = _take_int(d, "id")
	name = _take_str(d, "name")
	type = _take_int(d, "type")
	var _options := _try_arr(d, "options", [])
	for option: Dictionary in _options:
		options.append(ApplicationCommandInteractionDataOption.new(option))
	guild_id = _try_str(d, "guild_id", "").to_int()
	target_id = _try_str(d, "target_id", "").to_int()

#func reply() -> :
#TODO
