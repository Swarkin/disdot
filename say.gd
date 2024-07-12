extends CommandHandler

func _on_command(ctx: CommandContext) -> void:
	ctx.send(ctx.message.content.split(get_parent().prefix + name)[1])
