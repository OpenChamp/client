@tool
extends ggsUIComponent

@onready var text_field: LineEdit = $TextField


func _ready() -> void:
	compatible_types = [TYPE_STRING]
	if Engine.is_editor_hint():
		return
	
	super()
	text_field.text_submitted.connect(_on_text_field_text_submitted)


func init_value() -> void:
	super()
	text_field.text = setting_value


func _on_text_field_text_submitted(submitted_text: String) -> void:
	setting_value = submitted_text
	GGS.play_sfx(GGS.SFX.INTERACT)
	if apply_on_change:
		apply_setting()


### Setting

func reset_setting() -> void:
	super()
	text_field.text = setting_value
