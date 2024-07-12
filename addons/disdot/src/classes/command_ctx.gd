class_name CommandContext
extends RefCounted

var _api: DiscordAPI
var message: Message

func _init(__api: DiscordAPI, _message: Message) -> void:
	_api = __api
	message = _message


func send(content: String) -> void:
	await _api.create_message(message.channel_id, content)

func reply(content: String) -> void:
	await _api.create_message(message.channel_id, content, MessageReference.reply(message.id))
