class_name SlashCommandContext
extends RefCounted

var _api: DiscordAPI

func _init(__api: DiscordAPI) -> void:
	_api = __api
