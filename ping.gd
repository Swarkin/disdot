extends CommandHandler

func _on_command(ctx: CommandContext) -> void:
	ctx.send("pong")