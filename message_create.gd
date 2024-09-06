extends MessageCreateEventHandler

func _on_event(event: MessageCreateEvent) -> void:
	print("MessageCreate received: ", event.message.content)
	print("Bot? ", event.message.author.bot)
