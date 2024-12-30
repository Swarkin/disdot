class_name Payload
extends BetterBaseClass

enum Op {
	DISPATCH = 0,
	HEARTBEAT = 1,
	IDENTIFY = 2,
	PRESENCE_UPDATE = 3,
	VOICE_STATE_UPDATE = 4,
	RESUME = 6,
	RECONNECT = 7,
	REQUEST_GUILD_MEMBERS = 8,
	INVALID_SESSION = 9,
	HELLO = 10,
	HEARTBEAT_ACK = 11,
}

## [url=https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-opcodes]Gateway opcode[/url], which indicates the payload type
var op: Op
## Event data
var d: Variant
## Sequence number of event used for [url=https://discord.com/developers/docs/events/gateway#resuming]resuming sessions[/url] and [url=https://discord.com/developers/docs/events/gateway#sending-heartbeats]heartbeating[/url]
var s: Int
## Event name
var t: Str

func _init(_d: Dictionary) -> void:
	op = _take_int(_d, "op") as Op
	d = _try_take(_d, "d", {})
	var _s := _try_take(_d, "s")
	s = Int.new(_s) if _s else null
	var _t := _try_take(_d, "t")
	t = Str.new(_t) if _t else null

func to_dict() -> Dictionary:
	return {
		"op": op as int,
		"d": JSON.stringify(d),
		"s": null if op != Payload.Op.DISPATCH else s.value,
		"t": null if op != Payload.Op.DISPATCH else t.value,
	}
