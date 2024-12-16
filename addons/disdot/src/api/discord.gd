extends Node
class_name DiscordAPI

const BASE_URL := "https://discord.com/api/v10"
enum Type {
	STRING=3,
	INTEGER=4,
	BOOLEAN=5,
	USER=6,
	CHANNEL=7,
	ROLE=8,
	MENTIONABLE=9,
	NUMBER=10,
}

var token: ValueContainer
var app_id: ValueContainer


func _request(url: String, method := HTTPClient.METHOD_GET, custom_headers := PackedStringArray(), request_body := "") -> HTTPResult:
	var http := AwaitableHTTPRequest.new()
	http.accept_gzip = false
	http.timeout = 8.0

	get_tree().root.add_child.call_deferred(http)
	await http.ready

	var r := await http.async_request(url, custom_headers if !custom_headers.is_empty() else headers(), method, request_body)
	http.queue_free()
	return r

# TODO: query string support
func join(parts: PackedStringArray) -> String:
	const S := "/"
	var result := ""

	for p: String in parts:
		var part := p.strip_edges()
		result += part

		if not part.ends_with(S):
			result += S

	return result.trim_suffix("/")

func headers(json_content := true) -> PackedStringArray:
	var h := PackedStringArray([
		"Authorization: Bot "+token.get_value(),
		"User-Agent: disdot (%s, %s)" % ["https://github.com/Swarkin/disdot", ProjectSettings.get_setting("application/config/version")]
	])

	if json_content:
		h.append("Content-Type: application/json")

	return h


func get_gateway_bot() -> HTTPResult:
	var url := join([BASE_URL, "gateway", "bot"])
	return await _request(url, HTTPClient.METHOD_GET, headers())


func get_message(channel_id: int, message_id: int) -> HTTPResult:
	var url := join([BASE_URL, "channels", str(channel_id), "messages", str(message_id)])
	return await _request(url)

func create_message(channel_id: int, content: String, msg_ref: MessageReference = null) -> HTTPResult:
	var url := join([BASE_URL, "channels", str(channel_id), "messages"])

	var data := {"content": content}
	if msg_ref: data["message_reference"] = msg_ref.to_dict()

	return await _request(url, HTTPClient.METHOD_POST, headers(), JSON.stringify(data))

func delete_message(channel_id: int, message_id: int) -> HTTPResult:
	var url := join([BASE_URL, "channels", str(channel_id), "messages", str(message_id)])
	return await _request(url, HTTPClient.METHOD_DELETE)


func get_channel(channel_id: int) -> HTTPResult:
	var url := join([BASE_URL, "channels", str(channel_id)])
	return await _request(url)


func create_guild_application_command(guild_id: int, _name: String, description := "") -> HTTPResult:
	var url := join([BASE_URL, "applications", app_id.get_value(), "guilds", guild_id, "commands"])

	var data := {
		"name": _name,
		"description": description,
	}

	if description.is_empty():
		data.erase("description")

	return await _request(url, HTTPClient.METHOD_POST, headers(), JSON.stringify(data))


func create_interaction_response(id: int, token: String, response: InteractionResponse) -> HTTPResult:
	var url := join([BASE_URL, "interactions", str(id), token, "callback?with_response=true"])

	var data := response.to_dict()
	print_rich("[color=red]"+str(data)+"[/color]")

	return await _request(url, HTTPClient.METHOD_POST, headers(), JSON.stringify(data))
