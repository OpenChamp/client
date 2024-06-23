class_name UnitEffect
extends Timer


var cc_mask: int = 0
var effect_id: Identifier = null
var icon_id: Identifier = null


func _init(_effect_id: Identifier, _icon_id: Identifier, _cc_mask: int = 0):
	effect_id = _effect_id
	icon_id = _icon_id
	cc_mask = _cc_mask


func _ready() -> void:
	if cc_mask != 0:
		one_shot = true
		timeout.connect(Callable(get_parent(), "_on_cc_end").bind(self))
		start()


func end():
	queue_free()
