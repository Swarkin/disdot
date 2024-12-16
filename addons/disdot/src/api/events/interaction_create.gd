class_name InteractionCreateEvent
extends Event
## [url]https://discord.com/developers/docs/events/gateway-events#interaction-create[/url]
## Sent when a user uses an Application Command or Message Component.

var interaction: Interaction

func _init(d: Dictionary, _api: DiscordAPI) -> void:
	interaction = Interaction.new(d, _api)
