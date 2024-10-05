extends CommandHandler

func _on_command(ctx: CommandContext) -> void:
	# reply with the raw message content if its from an user
	if not ctx.message.author.bot:
		await ctx.reply(ctx.message.content)
