@icon("res://addons/disdot/src/icons/text_command.svg")
class_name TextCommandHandler
extends BaseCommandHandler

@export var ignore_bots := true

func _on_command(ctx: TextCommandContext) -> void:
	assert(false, "Cannot call function on abstract class")
