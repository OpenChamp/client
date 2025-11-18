@tool
class_name EAMDock
extends Control

@onready var reload_button: Button = $VSplitContainer/HBoxContainer/ReloadBtn
@onready var manage_button: Button = $VSplitContainer/HBoxContainer/ManageBtn
@onready var asset_tab_container := $VSplitContainer/AssetTabContainer

var config_window : Window

var asset_types := Identifier.get_all_resource_types()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reload_button.pressed.connect(_rebuild_asset_list)
	manage_button.pressed.connect(_open_config_window)
	_build_asset_list()


func _rebuild_asset_list():
	print('reloading asset list')
	
	for child in asset_tab_container.get_children():
		asset_tab_container.remove_child(child)
		child.queue_free()

	AssetIndexer.re_index_files()

	_build_asset_list()


func _build_asset_list():
	print('building asset list')
	
	AssetIndexer.index_files()
	var dynamic_assets := AssetIndexer.get_asset_map() as Dictionary
	print('got ' + str(dynamic_assets.size()) + ' assets from indexer')
	print(dynamic_assets)
	
	# create the containers for all the categories
	var category_continers = {}
	
	for asset_type in asset_types:
		var asset_tab_typed := VBoxContainer.new()
		asset_tab_typed.name = asset_type
		category_continers[asset_type] = asset_tab_typed	# add assets to their proper containers
	var asset_keys = dynamic_assets.keys()
	for key in asset_keys:
		# Extract the main asset type from the key (before the colon)
		var colon_index = key.find(':')
		if colon_index == -1:
			print('invalid asset key format: ' + key)
			continue
		
		var asset_type = key.substr(0, colon_index)
		
		# Skip if the asset type is not in our known types
		if asset_type not in category_continers:
			print('unknown asset type: ' + asset_type)
			continue
		
		var asset_id = Identifier.from_string(key)
		var content_id = asset_id.get_content_identifier()
		
		if content_id == null:
			print('got null as content id for: ' + asset_id.to_string())
			continue
		
		var asset_label_category = Label.new()
		
		asset_label_category.text = key
		asset_label_category.mouse_filter = Control.MOUSE_FILTER_STOP
		asset_label_category.tooltip_text = dynamic_assets[key]
		
		asset_label_category.gui_input.connect(
			func asset_callback(input_event):
				_copy_asset_id(input_event, asset_label_category.text)
		)
		category_continers[asset_type].add_child(asset_label_category)
		
	# add all tabs to the tab container
	for category_name in category_continers.keys():
		var tab_scroll = ScrollContainer.new()
		
		tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		#tab_scroll.clip_contents = false
		
		tab_scroll.name = category_continers[category_name].name
		tab_scroll.add_child(category_continers[category_name])
		asset_tab_container.add_child(tab_scroll)


func _copy_asset_id(input_event: InputEvent, clipboard_text: String):
	if input_event is InputEventMouseButton:
		if input_event.button_index == MOUSE_BUTTON_LEFT and input_event.pressed:
			print("callback for label " + clipboard_text + " entered")
			DisplayServer.clipboard_set(clipboard_text)

func _open_config_window():
	push_error("Config window not yet implemented.")
	# if config_window:
	# 	config_window.grab_focus()
	# 	return
	# config_window = Window.new()
	# EditorInterface.popup_dialog(config_window)
	# config_window.move_to_center()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
