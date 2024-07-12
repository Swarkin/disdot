class_name MessageCreateEvent
extends Event
## [url]https://discord.com/developers/docs/topics/gateway-events#message-create[/url]

func _init(d: Dictionary) -> void:
	message = Message.new(d)

var message: Message
