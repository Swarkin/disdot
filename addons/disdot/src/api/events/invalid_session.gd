class_name InvalidSessionEvent
extends Event
## [url]https://discord.com/developers/docs/events/gateway-events#invalid-session[/url]

var resumable: bool

func _init(d: Dictionary) -> void:
	resumable = _take_bool(d, "d")
