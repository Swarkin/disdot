extends RefCounted
class_name Int

func _init(_value: int) -> void:
	value = _value

var value: int

func _to_string() -> String:
	return str(value)
