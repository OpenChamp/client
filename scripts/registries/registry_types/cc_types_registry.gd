extends RegistryBase
class_name CCTypesRegistry


const CC_MASK_MOVEMENT = 0b1
const CC_MASK_CAST_MOBILITY = 0b10
const CC_MASK_ATTACK = 0b100
const CC_MASK_CAST = 0b1000
const CC_MASK_TARGET = 0b10000
const CC_MASK_TAKE_DAMAGE = 0b100000

const CC_MASKS = {
	"movement": CC_MASK_MOVEMENT,
	"cast_mobility": CC_MASK_CAST_MOBILITY,
	"attack": CC_MASK_ATTACK,
	"cast": CC_MASK_CAST,
	"target": CC_MASK_TARGET,
	"take_damage": CC_MASK_TAKE_DAMAGE
}

var _internal_values: Dictionary = {}


func _load_default_cc(id_string, impairments):
	var cc_id = Identifier.from_string(id_string)
	var cc_icon = Identifier.for_resource("texture://openchamp:cc_type_fallback")
	var cc_impairments = 0

	for impairment in impairments:
		cc_impairments |= CC_MASKS[impairment]

	var cc_type = CCType.new(cc_id, cc_icon, cc_impairments)
	_internal_values[id_string] = cc_type


func _init():
	_json_type = "cc_types"

	_load_default_cc("openchamp:disarmed", ["attack"])
	_load_default_cc("openchamp:silenced", ["cast", "cast_mobility"])
	_load_default_cc("openchamp:rooted", ["movement", "cast_mobility"])
	_load_default_cc("openchamp:stunned", ["cast", "attack", "cast_mobility", "movement"])
	_load_default_cc("openchamp:stasis", ["take_damage", "cast", "attack", "cast_mobility", "movement"])


func contains(_item: String) -> bool:
	return _internal_values.has(_item)


func get_element(_item: String):
	return _internal_values[_item]


func load_from_json(_json: Dictionary) -> bool:
	if not can_load_from_json(_json):
		return false

	if int(_json["format_version"]) != 1:
		print("Error: Attempted to load a CC Types registry with an invalid format version.")
		return false

	if not _json.has("data"):
		print("Error: Attempted to load a CC Types registry with no data.")
		return false

	var data_array = _json["data"] as Array
	if data_array == null:
		print("Error: CC Types data is not an array.")
		return false

	for cc_type_data in data_array:
		var data = cc_type_data as Dictionary
		if data == null:
			print("Error: CC Type data is not a dictionary.")
			continue
		
		if not data.has("id"):
			print("Error: CC Type data has no ID.")
			continue

		var cc_string_id = data["id"] as String
		if cc_string_id == null:
			print("Error: CC Type ID is not a string.")
			continue

		if _internal_values.has(cc_string_id):
			print("Error: CC Type ID " + cc_string_id + " is already in use.")
			continue

		var cc_id = Identifier.from_string(cc_string_id)

		var cc_icon_res = "texture://openchamp:cc_type_fallback"
		if data.has("icon"):
			cc_icon_res = "texture://" + (data["icon"] as String)
		else:
			print("Error: no icon for CC Type " + str(data["id"]) + ", using the fallback icon.")
		
		var cc_icon := Identifier.for_resource(cc_icon_res)

		if not data.has("impairments"):
			print("Error: CC Type data has no impairments.")
			continue

		var cc_impairments := 0
		var impairments_array = data["impairments"] as Array

		if impairments_array == null:
			print("Error: CC Type impairments is not an array.")
			continue

		for impairment in impairments_array:
			if not _internal_values.has(impairment):
				print("Error: CC Type impairment " + impairment + " is not a valid impairment.")
				continue

			cc_impairments |= _internal_values[impairment]

		var cc_type = CCType.new(cc_id, cc_icon, cc_impairments)
		_internal_values[cc_string_id] = cc_type

	return true
