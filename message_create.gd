extends MessageCreateEventHandler

func _on_event(event: MessageCreateEvent) -> void:
	var bot := event.message.author.bot
	print("MessageCreate received: ", event.message.content)
	print("Message from bot? ", bot)

	if not bot:
		#var channel := await event.message.get_channel()
		#await channel.send("hello!")
		pass
