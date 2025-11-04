class_name GameTimer
extends Timer

var times = []

func toggle():
	times.push(Time.get_ticks_usec())
