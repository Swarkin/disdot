extends Resource
class_name ValueContainer

## test

@export_enum("Property", "File") var source: int
@export var value: String
@export_file var file_path: String


func get_value() -> String:
	if source == 0:
		return value

	value = FileAccess.get_file_as_string(file_path).strip_escapes()
	if value.is_empty():
		var err := FileAccess.get_open_error()
		if err:
			push_error("Failed to read file \'"+file_path+"\': "+error_string(err))
			return ""

	source = 0
	return value
