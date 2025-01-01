extends TextCommandHandler

func _on_command(ctx: TextCommandContext, args: Dictionary[String, Variant] = {}) -> void:
	# note: bot messages are filtered out by the 'Ignore Bots' property of TextCommandHandler.
	for i in min(args["count"], 3):
		await ctx.reply(args["text"])
