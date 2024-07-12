class_name ReadyEvent
extends Event
## [url]https://discord.com/developers/docs/topics/gateway-events#ready[/url]

func _init(d: Dictionary) -> void:
	v = _try_take(d, "v", 0) as int

var v: int
