extends Timer

signal ping_response(id: int, latency: int)
var PING_START:int = 0

func _ready() -> void:
	if ConfigManager.client_mode != ConfigManager.CLIENTMODE.DEDICATED_SERVER: return;
	timeout.connect(_on_ping_timer_timeout)
	start()

@rpc("authority")
func ping():
	rpc_id(1, "pong")

@rpc("any_peer")
func pong():
	var now = Time.get_ticks_msec()
	var id = multiplayer.get_remote_sender_id()
	emit_signal("ping_response", id, now - PING_START)

func _on_ping_timer_timeout() -> void:
	if not ConfigManager.CLIENTMODE.DEDICATED_SERVER: stop(); return
	PING_START = Time.get_ticks_msec()
	rpc("ping")
