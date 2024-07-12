extends RefCounted
class_name Str

func _init(_value: String) -> void:
	value = _value

var value: String

func _to_string() -> String:
	return value
