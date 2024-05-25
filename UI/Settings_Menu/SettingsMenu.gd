extends Control

@onready var ConfirmBtn = $SplitContainer/PanelContainer2/GridContainer/ConfirmBtn
@onready var ExitBtn = $SplitContainer/PanelContainer2/GridContainer/ExitBtn

@onready var fullscreen_toggle = $SplitContainer/PanelContainer/TabContainer/Display/FullscreenToggleBtn

# Called when the node enters the scene tree for the first time.
func _ready():
	ExitBtn.pressed.connect(_on_game_close_pressed)
	ConfirmBtn.pressed.connect(_on_confirm_changes)
	
	fullscreen_toggle.button_pressed = Config.is_fullscreen
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_game_close_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_confirm_changes():
	Config.set_fullscreen_mode(fullscreen_toggle.button_pressed)
	hide()
