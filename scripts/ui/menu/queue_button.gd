extends Button

var is_in_queue := false

func _ready() -> void:
	pressed.connect(_on_pressed)
	update_button()

func _on_pressed() -> void:
	if is_in_queue:
		WSManager.leave_queue()
	else:
		WSManager.join_queue()
	is_in_queue = !is_in_queue
	update_button()

func update_button() -> void:
	if is_in_queue:
		text = "Leave Queue"
	else:
		text = "Join Queue"
