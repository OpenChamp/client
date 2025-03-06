@tool
extends Popup

@onready var label = %Label
@onready var progress_bar = %ProgressBar

func set_label(text: String) -> void:
	label.text = text

func update_progress(value, max_value) -> void:
	progress_bar.max_value = max_value
	progress_bar.value = value
