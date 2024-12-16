class_name MessageInteractionCallbackData
extends BaseInteractionCallbackData
## [url]https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object-messages[/url]

var tts: bool
var content: String
#var embeds: Array[Embed]
#var allowed_mentions: AllowedMentions
#var flags: int
#var components: Array[Component]
#var attachments: Array[Attachment]
#var poll: Poll

func _init(_content: String, _tts := false) -> void:
	content = _content
	tts = _tts

func to_dict() -> Dictionary:
	# FIXME: find a way of calling super.to_dict() two classes behind
	return {"tts": tts, "content": content}
