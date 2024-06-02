@tool
extends ggsUIComponent

@onready var spin_box: SpinBox = $SpinBox
@onready var field: LineEdit = spin_box.get_line_edit()


func _ready() -> void:
	compatible_types = [TYPE_INT, TYPE_FLOAT]
	if Engine.is_editor_hint():
		return
	
	super()
	spin_box.value_changed.connect(_on_spin_box_value_changed)
	field.context_menu_enabled = false


func init_value() -> void:
	super()
	spin_box.set_value_no_signal(setting_value)
	field.text = str(setting_value)


func _on_spin_box_value_changed(new_value: float) -> void:
	setting_value = new_value
	GGS.play_sfx(GGS.SFX.INTERACT)
	if apply_on_change:
		apply_setting()


### Setting

func reset_setting() -> void:
	super()
	spin_box.value = setting_value
	field.text = str(setting_value)
