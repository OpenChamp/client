class_name UnitEffect
extends Timer


var cc_mask: int

func _ready() -> void:
	one_shot = true
	timeout.connect(Callable(get_parent(), "_on_cc_end").bind(self))
	start()


func end():
	queue_free()
