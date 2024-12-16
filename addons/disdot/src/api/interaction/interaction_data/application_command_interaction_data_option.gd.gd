class_name ApplicationCommandInteractionDataOption
extends BetterBaseClass
## [url]https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-application-command-interaction-data-option-structure[/url]

enum ApplicationCommandOptionType {
	SUB_COMMAND = 1,
	SUB_COMMAND_GROUP = 2,
	STRING = 3,
	INTEGER = 4,  ## Any integer between -2^53 and 2^53
	BOOLEAN = 5,
	USER = 6,
	CHANNEL = 7,  ## Includes all channel types + categories
	ROLE = 8,
	MENTIONABLE = 9,  ## Includes users and roles
	NUMBER = 10,  ## Any double between -2^53 and 2^53
	ATTACHMENT = 11,
}

var name: String
var type: int
var value: Variant
var options: Array[ApplicationCommandInteractionDataOption]
#var focused: bool

func _init(d: Dictionary) -> void:
	name = _take_str(d, "name")
	type = _take_int(d, "type") as ApplicationCommandOptionType
	value = _try_take(d, "", null)
	var _options := _try_arr(d, "options", [])
	for option: Dictionary in _options:
		options.append(ApplicationCommandInteractionDataOption.new(option))
	#focused = _try_bool(d, "focused", false)
