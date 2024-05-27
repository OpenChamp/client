extends Control

@onready var ConfirmBtn = $SplitContainer/PanelContainer2/GridContainer/ConfirmBtn
@onready var ExitBtn = $SplitContainer/PanelContainer2/GridContainer/ExitBtn

# display setting element
@onready var fullscreen_toggle = $SplitContainer/PanelContainer/TabContainer/Display/FullscreenToggleBtn

# camera setting elements
@onready var cam_speed_slider = $SplitContainer/PanelContainer/TabContainer/Camera/cam_speed_slider
@onready var edge_margin_slider = $SplitContainer/PanelContainer/TabContainer/Camera/edge_margin_slider
@onready var max_zoom_slider = $SplitContainer/PanelContainer/TabContainer/Camera/max_zoom_slider
@onready var cam_centered_toggle = $SplitContainer/PanelContainer/TabContainer/Camera/CamCenteredToggleBtn

func _ready():
	visibility_changed.connect(on_show)
	
	ExitBtn.pressed.connect(_on_game_close_pressed)
	ConfirmBtn.pressed.connect(_on_confirm_changes)


func on_show():
	Config.in_config_settings = visible
	if not visible:
		return
	
	fullscreen_toggle.button_pressed = Config.is_fullscreen
	
	cam_speed_slider.value = Config.cam_speed
	edge_margin_slider.value = Config.edge_margin
	max_zoom_slider.value = Config.max_zoom
	max_zoom_slider.min_value = Config.min_zoom + 1
	cam_centered_toggle.button_pressed = Config.is_cam_centered


func _on_game_close_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func _on_confirm_changes():
	var all_settings = GGS.get_all_settings()
	for setting_str in all_settings:
		var setting: ggsSetting = load(setting_str)
		_apply_setting(setting)
		
	hide()


func _apply_setting(setting: ggsSetting):
	var new_value;
	match setting.name:
		# display options
		"fullscreen":
			new_value = fullscreen_toggle.button_pressed
			Config.is_fullscreen = new_value
		# camera options:
		"cam_speed":
			new_value = cam_speed_slider.value
			Config.cam_speed = new_value
		"edge_margin":
			new_value = edge_margin_slider.value
			Config.edge_margin = new_value
		"max_zoom":
			new_value = max_zoom_slider.value
			Config.max_zoom = new_value
		"cam_centered":
			new_value = cam_centered_toggle.button_pressed
			Config.is_cam_centered = new_value
		_ :
			pass
	
	setting.set_current(new_value)
