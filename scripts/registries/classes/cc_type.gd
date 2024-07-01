extends Object
class_name CCType


var cc_id: Identifier = null
var cc_mask: int = 0
var icon_id: Identifier = null


func _init(_cc_id: Identifier, _icon_id: Identifier, _cc_mask: int):
	self.cc_id = _cc_id
	self.cc_mask = _cc_mask
	self.icon_id = _icon_id


func apply_to_unit(unit: Unit, base_duration: float):
	var unit_cc_timer = UnitEffect.new(cc_id, icon_id, cc_mask)
	unit_cc_timer.set_wait_time(base_duration)
	
	unit.apply_effect(unit_cc_timer)
	