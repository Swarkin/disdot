extends ReadyEventHandler

func _on_event(event: ReadyEvent) -> void:
	# api version:
	prints("API version:", event.v)

	# bot user:
	prints("Bot user:", event.user)
