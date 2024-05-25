extends Control

@onready var ConfirmBtn = $SplitContainer/PanelContainer2/GridContainer/ConfirmBtn
@onready var ExitBtn = $SplitContainer/PanelContainer2/GridContainer/ExitBtn

# Called when the node enters the scene tree for the first time.
func _ready():
	ExitBtn.pressed.connect(_on_game_close_pressed)
	ConfirmBtn.pressed.connect(_on_confirm_changes)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_game_close_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_confirm_changes():
	hide()
