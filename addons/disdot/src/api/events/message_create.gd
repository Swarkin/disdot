class_name MessageCreateEvent
extends Event
## [url]https://discord.com/developers/docs/topics/gateway-events#message-create[/url]

func _init(d: Dictionary, api: DiscordAPI) -> void:
	message = Message.new(d, api)

var message: Message
