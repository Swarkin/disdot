extends EventHandler

func _on_event(event: MessageCreateEvent) -> void:
	print("MessageCreate received: ", event.message.content)
