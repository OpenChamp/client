extends Timer

func _process(delta):
	if get_parent().is_dead:
		if(is_stopped()):
			start()
	$"../Dead/Panel/RespawnTimeText".text = str(time_left)
