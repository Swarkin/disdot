extends MessageCreateEventHandler

func _on_event(event: MessageCreateEvent) -> void:
	print("MessageCreate received")

	# access the user that sent the message:
	var user := event.message.author
	prints("User:", user.username)

	# check whether the message was sent by a bot
	var bot := user.bot
	prints("Sent by a bot?", bot)

	# to echo non-bot messages:
	if not bot:
		await event.message.reply(event.message.content)
