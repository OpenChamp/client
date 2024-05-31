class_name JsonTranslation
extends Translation


static func fromJson(json_resource: JSON, _locale: String = "en") -> JsonTranslation:
	var translation = JsonTranslation.new()
	translation.locale = _locale

	print(_locale + " translation from JSON: ", json_resource)

	if json_resource == null:
		return translation

	if typeof(json_resource.data) != TYPE_DICTIONARY:
		return translation

	var json_data = json_resource.data as Dictionary

	for key in json_data.keys():
		translation.add_message(key, json_data[key])
	
	return translation
