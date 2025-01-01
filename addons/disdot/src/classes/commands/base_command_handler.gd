class_name BaseCommandHandler
extends Node

var _parameters: Array[BaseCommandParameter]
var _required_count := -1

func _ready() -> void:
	_update_parameters()

func _update_parameters() -> void:
	_parameters.clear()
	for c in get_children():
		if c is BaseCommandParameter:
			_parameters.append(c)

	var optional_reached := false

	for p in _parameters:
		if p.required:
			_required_count += 1
			if optional_reached:
				push_error("Cannot have required parameters after optional parameters")
				_required_count = -1
				return
		else:
			optional_reached = true
