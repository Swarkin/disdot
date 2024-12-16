class_name InteractionResponse
extends BetterBaseClass
## [url]https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object[/url]
# Used for the callback HTTP request

enum CallbackType {
	CHANNEL_MESSAGE_WITH_SOURCE = 4,
	#DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE = 5,
	# ...
}

var type: CallbackType
var data: BaseInteractionCallbackData

func _init(_type: CallbackType, _data: BaseInteractionCallbackData) -> void:
	type = _type
	data = _data

func to_dict() -> Dictionary:
	match type:
		CallbackType.CHANNEL_MESSAGE_WITH_SOURCE:
			return {
				"type": type as int,
				"data": (data as MessageInteractionCallbackData).to_dict()
			}
		_:
			push_error("Unsupported CallbackType for Interaction")
			return {}
