class_name BetterBaseClass
extends RefCounted
## BetterBaseClass v1.4.0 by swark1n

func _init(dict := {}) -> void:
	for key in dict:
		if key is not String:
			print_rich('[color=khaki]Invalid type of ke \'', key, '\'.[/color]')
			continue

		@warning_ignore('inference_on_variant')
		var other_value := dict.get(key)
		var other_value_type := typeof(other_value)

		if other_value_type == TYPE_NIL:
			print_rich('[color=khaki]Received null value from key \'', key, '\'.[/color]')
			continue

		# Check if property is present in self
		if not key in self:
			print_rich('[color=khaki]Unknown key \'', key, '\' with value \'', other_value, '\' of type \'', type_string(other_value_type), '\'.[/color]')
			continue

		@warning_ignore('inference_on_variant')
		var self_value := self[key] as Variant
		var self_value_type := typeof(self_value)

		# Check if the types match
		if not other_value_type == self_value_type:
			# Try to convert float to int (JSON decodes int values as float)
			if other_value_type == TYPE_FLOAT and self_value_type == TYPE_INT:
				print_rich('[color=khaki]Converting key \'', key, '\' with value \'', other_value, '\' from type \'', type_string(other_value_type), '\' to \'', type_string(self_value_type), '\'.[/color]')
				other_value = type_convert(other_value, self_value_type)
			else:
				print_rich('[color=khaki]Incompatible type of \'', key, '\' with value \'', other_value, '\' type \'', type_string(other_value_type), '\', expected type \'', type_string(self_value_type), '\'.[/color]')
				continue

		# Check if array has the correct type
		if self_value_type == TYPE_ARRAY:
			@warning_ignore('unsafe_method_access', 'unsafe_cast') var self_arr_type := self_value.get_typed_builtin() as Variant.Type
			@warning_ignore('unsafe_method_access', 'unsafe_cast') var other_arr_type := other_value.get_typed_builtin() as Variant.Type
			if not self_arr_type == other_arr_type:
				print_rich('[color=khaki]Incompatible array type: expected \'', type_string(self_arr_type), '\', got \'', type_string(other_arr_type), '\'.[/color]')
				continue

		# Finally:
		self[key] = dict[key]


static func _try_take(d: Dictionary, key: String, default: Variant) -> Variant:
	var v := d.get(key)
	if v:
		d.erase(key)
		return v
	return default

static func _try_int(d: Dictionary, key: String, default: int) -> int:
	var v := d.get(key)
	if v:
		assert(typeof(v) == TYPE_INT)
		d.erase(key)
		return v as int
	return default

static func _try_str(d: Dictionary, key: String, default: String) -> String:
	var v := d.get(key)
	if v:
		assert(typeof(v) == TYPE_STRING)
		d.erase(key)
		return v as String
	return default

static func _try_bool(d: Dictionary, key: String, default: bool) -> bool:
	var v := d.get(key)
	if v:
		assert(typeof(v) == TYPE_BOOL)
		d.erase(key)
		return v as bool
	return default

static func _try_arr(d: Dictionary, key: String, default: Array) -> Array:
	var v := d.get(key)
	if v:
		assert(typeof(v) == TYPE_ARRAY)
		d.erase(key)
		return v as Array
	return default

static func _try_dict(d: Dictionary, key: String, default: Dictionary) -> Dictionary:
	var v := d.get(key)
	if v:
		assert(typeof(v) == TYPE_DICTIONARY)
		d.erase(key)
		return v as Dictionary
	return default

static func _take(d: Dictionary, key: String) -> Variant:
	var v := d.get(key)
	assert(d.erase(key))
	return v

static func _take_int(d: Dictionary, key: String) -> int:
	var v := d.get(key) as int
	assert(d.erase(key))
	return v

static func _take_str(d: Dictionary, key: String) -> String:
	var v := d.get(key) as String
	assert(d.erase(key))
	return v

static func _take_bool(d: Dictionary, key: String) -> bool:
	var v := d.get(key) as bool
	assert(d.erase(key))
	return v

static func _take_arr(d: Dictionary, key: String) -> Array:
	var v := d.get(key) as Array
	assert(d.erase(key))
	return v

static func _take_dict(d: Dictionary, key: String) -> Dictionary:
	var v := d.get(key) as Dictionary
	assert(d.erase(key))
	return v


func _to_string() -> String:
	const SEP := ', '
	var s := (get_script() as Script).get_global_name()+': '
	var p_list := get_property_list()

	for p in p_list:
		if p.get('usage') == PROPERTY_USAGE_SCRIPT_VARIABLE:
			var n := p.get('name')
			s += n+' = '+str(self[n])+SEP

	return '['+s.trim_suffix(SEP)+']'

# non-recursive
func to_dict() -> Dictionary:
	var d := {}
	var p_list := get_property_list()

	for p in p_list:
		if p.get('usage') == PROPERTY_USAGE_SCRIPT_VARIABLE:
			var n := p.get('name')
			d[n] = self[n]

	return d
