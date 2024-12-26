extends CommandHandler

func _on_command(ctx: CommandContext) -> void:
	# reply with the raw message content
	# bots are filtered by the 'Ignore Bots' property of CommandHandler, see inspector
	await ctx.reply(ctx.message.content)
