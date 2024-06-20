class_name CCEffect
extends Timer

var cc_mask: int

func _ready() -> void:
	timeout.connect(Callable(get_parent(), "_on_cc_end").bind(self))
	start()
