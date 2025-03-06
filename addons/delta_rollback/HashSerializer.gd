extends RefCounted

func serialize(value):
	if value is Dictionary:
		return serialize_dictionary(value)
	elif value is Array:
		return serialize_array(value)
	elif value is Resource:
		return serialize_resource(value)
	elif value is Object:
		return serialize_object(value)
	
	return serialize_other(value)

func serialize_dictionary(value: Dictionary) -> Dictionary:
	var serialized := {}
	for key in value:
		serialized[key] = serialize(value[key])
	return serialized

func serialize_array(value: Array):
	var serialized := []
	for item in value:
		serialized.append(serialize(item))
	return serialized

func serialize_resource(value: Resource):
	return {
		'_' = 'resource',
		path = value.resource_path,
	}

func serialize_object(value: Object):
	return {
		'_' = 'object',
		string = value.to_string(),
	}

func serialize_other(value):
	if value is Vector2:
		return {
			'_' = 'Vector2',
			x = value.x,
			y = value.y,
		}
	elif value is Vector3:
		return {
			'_' = 'Vector3',
			x = value.x,
			y = value.y
		}
	elif value is Transform2D:
		return {
			'_' = 'Transform2D',
			x = {x = value.x.x, y = value.x.y},
			y = {x = value.y.x, y = value.y.y},
			origin = {x = value.origin.x, y = value.origin.y},
		}
	elif value is Transform3D:
		return {
			'_' = 'Transform3D',
			x = {x = value.x.x, y = value.x.y, z = value.x.z},
			y = {x = value.y.x, y = value.y.y, z = value.y.z},
			z = {x = value.z.x, y = value.z.y, z = value.z.z},
			origin = {x = value.origin.x, y = value.origin.y, z = value.origin.z},
		}
	
	return value

func unserialize(value):
	if value is Dictionary:
		if not value.has('_'):
			return unserialize_dictionary(value)
		
		if value['_'] == 'resource':
			return unserialize_resource(value)
		elif value['_'] in ['Vector2', 'Vector3', 'Transform2D', 'Transform']:
			return unserialize_other(value)
		
		return unserialize_object(value)
	elif value is Array:
		return unserialize_array(value)
	return value

func unserialize_dictionary(value: Dictionary):
	var unserialized := {}
	for key in value:
		unserialized[key] = unserialize(value[key])
	return unserialized

func unserialize_array(value: Array):
	var unserialized := []
	for item in value:
		unserialized.append(unserialize(item))
	return unserialized

func unserialize_resource(value: Dictionary):
	return load(value['path'])

func unserialize_object(value: Dictionary):
	if value['_'] == 'object':
		return value['string']
	return null

func unserialize_other(value: Dictionary):
	match value['_']:
		'Vector2':
			return Vector2(value.x, value.y)
		'Vector3':
			return Vector3(value.x, value.y, value.z)
		'Transform2D':
			return Transform2D(
				Vector2(value.x.x, value.x.y),
				Vector2(value.y.x, value.y.y),
				Vector2(value.origin.x, value.origin.y)
			)
		'Transform3D':
			return Transform3D(
				Vector3(value.x.x, value.x.y, value.x.z),
				Vector3(value.y.x, value.y.y, value.y.z),
				Vector3(value.z.x, value.z.y, value.z.z),
				Vector3(value.origin.x, value.origin.y, value.origin.z)
			)
	
	return null
