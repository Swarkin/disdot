class_name Payload
extends BetterBaseClass

## [url=https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-opcodes]Gateway opcode[/url], which indicates the payload type
var op: int
## Event data
var d: Variant
## Sequence number of event used for [url=https://discord.com/developers/docs/events/gateway#resuming]resuming sessions[/url] and [url=https://discord.com/developers/docs/events/gateway#sending-heartbeats]heartbeating[/url]
var s: Int
## Event name
var t: Str

func _init(_d: Dictionary) -> void:
	op = _take_int(_d, "id")
	d = _try_take(_d, "d", {})
	var _s := _try_take(_d, "s")
	s = Int.new(_s) if _s else null
	var _t := _try_take(_d, "t")
	t = Str.new(_t) if _t else null

func to_dict() -> Dictionary:
	return {
		"op": op,
		"d": JSON.stringify(d),
		"s": null if op != Disdot.Op.DISPATCH else s.value,
		"t": null if op != Disdot.Op.DISPATCH else t.value,
	}
