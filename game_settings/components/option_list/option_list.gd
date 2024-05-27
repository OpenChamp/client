@tool
extends ggsUIComponent

@export var use_ids: bool = false

@onready var btn: OptionButton = $Btn


func _ready() -> void:
	compatible_types = [TYPE_BOOL, TYPE_INT]
	if Engine.is_editor_hint():
		return
	
	super()
	btn.item_selected.connect(_on_btn_item_selected)
	
	btn.pressed.connect(_on_btn_pressed)
	btn.mouse_entered.connect(_on_btn_mouse_entered)
	btn.focus_entered.connect(_on_btn_focus_entered)
	btn.item_focused.connect(_on_btn_item_focused)


func init_value() -> void:
	super()
	
	if use_ids:
		btn.select(btn.get_item_index(setting_value))
	else:
		btn.select(setting_value)


func _on_btn_item_selected(item_index: int) -> void:
	GGS.play_sfx(GGS.SFX.INTERACT)
	
	if use_ids:
		setting_value = btn.get_item_id(item_index)
	else:
		setting_value = item_index
	if apply_on_change:
		apply_setting()


### Setting

func reset_setting() -> void:
	super()
	btn.select(setting_value)


### SFX

func _on_btn_pressed() -> void:
	GGS.play_sfx(GGS.SFX.FOCUS)


func _on_btn_mouse_entered() -> void:
	GGS.play_sfx(GGS.SFX.MOUSE_OVER)
	
	if grab_focus_on_mouse_over:
		btn.grab_focus()


func _on_btn_focus_entered() -> void:
	GGS.play_sfx(GGS.SFX.FOCUS)


func _on_btn_item_focused(_index: int) -> void:
	GGS.play_sfx(GGS.SFX.FOCUS)
