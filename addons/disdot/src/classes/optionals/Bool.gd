extends RefCounted
class_name Bool

func _init(_value: bool) -> void:
	value = _value

var value: bool

func _to_string() -> String:
	return str(value)
