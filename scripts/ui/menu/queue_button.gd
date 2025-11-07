extends Button

var is_in_queue := false

func _ready() -> void:
	WSManager.joined_queue.connect(_on_queue_joined)
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if is_in_queue:
		WSManager.leave_queue()
		is_in_queue = false
		text = "Join Queue"
	else:
		WSManager.join_queue()

func _on_queue_joined():
	text = "Leave Queue"
	is_in_queue = true
