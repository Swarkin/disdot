extends InteractionCreateEventHandler

func _on_event(event: InteractionCreateEvent) -> void:
	print("\n".repeat(5))
	print(event.to_string())
	print("\n".repeat(5))
	event.interaction.respond("hello, world!")
