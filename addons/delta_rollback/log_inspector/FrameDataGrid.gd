@tool
extends Tree

const Logger = preload("res://addons/delta_rollback/Logger.gd")
const LogData = preload("res://addons/delta_rollback/log_inspector/LogData.gd")

var log_data: LogData
var cursor_time: int = -1: set = set_cursor_time

enum PropertyType {
	BASIC,
	ENUM,
	TIME,
	SKIPPED,
}

var _property_definitions := {}

func set_log_data(_log_data: LogData) -> void:
	log_data = _log_data

func set_cursor_time(_cursor_time: int) -> void:
	if cursor_time != _cursor_time:
		cursor_time = _cursor_time
		refresh_from_log_data()

func _ready() -> void:
	_property_definitions['frame_type'] = {
		type = PropertyType.ENUM,
		values = Logger.FrameType.keys(),
	}
	_property_definitions['tick'] = {}
	_property_definitions['input_tick'] = {}
	_property_definitions['duration'] = {
		suffix = ' ms',
	}
	_property_definitions['fatal_error'] = {}
	_property_definitions['fatal_error_message'] = {}
	_property_definitions['skipped'] = {}
	_property_definitions['skip_reason'] = {
		type = PropertyType.ENUM,
		values = Logger.SkipReason.keys(),
	}
	_property_definitions['buffer_underrun_message'] = {}
	_property_definitions['start_time'] = {
		type = PropertyType.TIME,
	}
	_property_definitions['end_time'] = {
		type = PropertyType.TIME,
	}
	_property_definitions['timings'] = {
		type = PropertyType.SKIPPED,
	}

	refresh_from_log_data()

func refresh_from_log_data() -> void:
	clear()
	var root = create_item()

	if log_data == null or log_data.is_loading() or log_data.peer_ids.size() == 0:
		set_column_titles_visible(false)
		var empty = create_item(root)
		empty.set_text(0, "No data.")
		return

	var frames := {}
	var prop_names := []
	var extra_prop_names := []
	var index: int

	columns = log_data.peer_ids.size() + 1
	set_column_titles_visible(true)

	index = 1
	for peer_id in log_data.peer_ids:
		set_column_title(index, "Peer %s" % peer_id)
		index += 1

		var frame: LogData.FrameData = log_data.get_frame_by_time(peer_id, log_data.start_time + cursor_time)
		frames[peer_id] = frame
		if frame:
			for prop_name in frame.data:
				if not _property_definitions.has(prop_name):
					if not prop_name in extra_prop_names:
						extra_prop_names.append(prop_name)
				elif not prop_name in prop_names:
					prop_names.append(prop_name)

	for prop_name in _property_definitions:
		if not prop_name in prop_names:
			continue

		var prop_def = _property_definitions.get(prop_name)
		if prop_def.get('type') == PropertyType.SKIPPED:
			continue
		var row = create_item(root)
		row.set_text(0, prop_def.get('label', prop_name.capitalize()))

		index = 1
		for peer_id in log_data.peer_ids:
			var frame = frames[peer_id]
			if frame:
				row.set_text(index, _prop_to_string(frame.data, prop_name, prop_def))
			index += 1

	for prop_name in extra_prop_names:
		var row = create_item(root)
		row.set_text(0, prop_name.capitalize())

		index = 1
		for peer_id in log_data.peer_ids:
			var frame = frames[peer_id]
			if frame:
				row.set_text(index, _prop_to_string(frame.data, prop_name, {}))
			index += 1

	if 'timings' in prop_names:
		var timings_root = create_item(root)
		timings_root.set_text(0, "Timings")
		_add_timings(timings_root, frames)

func _prop_to_string(data: Dictionary, prop_name: String, prop_def = null) -> String:
	if prop_def == null:
		prop_def = _property_definitions.get(prop_name, {})
	var prop_type = prop_def.get('type', PropertyType.BASIC)

	var value = data.get(prop_name, prop_def.get('default', null))

	match prop_type:
		PropertyType.ENUM:
			if value != null and prop_def.has('values'):
				var values = prop_def['values']
				if value >= 0 and value < values.size():
					value = values[value]

		PropertyType.BASIC:
			if prop_def.has('values'):
				value = prop_def['values'].get(value, value)

		PropertyType.TIME:
			if value != null:
				var datetime = Time.get_datetime_dict_from_unix_time(value / 1000)
				value = "%04d-%02d-%02d %02d:%02d:%02d" % [
					datetime['year'],
					datetime['month'],
					datetime['day'],
					datetime['hour'],
					datetime['minute'],
					datetime['second'],
				]

	if value == null:
		return ''

	value = str(value)
	if prop_def.has('suffix'):
		value += prop_def['suffix']

	return value

func _add_timings(root: TreeItem, frames: Dictionary) -> void:
	var all_timings := {}
	for peer_id in log_data.peer_ids:
		var frame = frames[peer_id]
		if frame:
			for key in frame.data.get('timings', {}):
				all_timings[key] = true

	var all_timings_names = all_timings.keys()
	all_timings_names.sort()

	var items := {}
	for timing_name in all_timings_names:
		var timing_name_parts = timing_name.split('.')
		var item = _create_nested_item(timing_name_parts, root, items)
		var index = 1
		for peer_id in log_data.peer_ids:
			var frame = frames[peer_id]
			if frame:
				var timing = frame.data.get('timings', {}).get(timing_name)
				if timing != null:
					if timing_name_parts[timing_name_parts.size() - 1] != 'count':
						timing = str(timing) + ' ms'
					else:
						timing = str(timing)
					item.set_text(index, timing)
			index += 1

func _create_nested_item(name_parts: Array, root: TreeItem, items: Dictionary) -> TreeItem:
	if name_parts.size() == 0:
		return null

	var name = '.'.join(PackedStringArray(name_parts))
	if items.has(name):
		return items[name]

	var item: TreeItem
	if name_parts.size() == 1:
		item = create_item(root)
	else:
		var parent_parts = name_parts.slice(0, name_parts.size() - 2)
		var parent: TreeItem = _create_nested_item(parent_parts, root, items)
		item = create_item(parent)

	item.set_text(0, name_parts[name_parts.size() - 1].capitalize())
	item.collapsed = true
	items[name] = item

	return item
