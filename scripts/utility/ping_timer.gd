extends Timer

var PING_START:int = 0
func _ready() -> void:
	timeout.connect(_on_ping_timer_timeout)
	start()

@rpc("authority")
func ping():
	rpc_id(1, "pong")

@rpc("any_peer")
func pong():
	var now = Time.get_ticks_msec()
	var id = multiplayer.get_remote_sender_id()
	if Util.players.has(id):
		Util.players[id].set("ping", now - PING_START)
	else:
		print(now - PING_START)

func _on_ping_timer_timeout() -> void:
	if not Util.dedicated_server: stop(); return
	PING_START = Time.get_ticks_msec()
	rpc("ping")
	pass # Replace with function body.
