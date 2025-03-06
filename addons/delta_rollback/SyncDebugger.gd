extends Node

const DebugOverlay = preload("res://addons/delta_rollback/debugger/DebugOverlay.tscn")
const DebugStateComparer = preload("res://addons/delta_rollback/DebugStateComparer.gd")

const JSON_INDENT = "    "

var _canvas_layer
var _debug_overlay
var _debug_pressed: bool = false

var print_previous_state := false

func _ready() -> void:
	SyncManager.rollback_flagged.connect(_on_SyncManager_rollback_flagged)
	SyncManager.prediction_missed.connect(_on_SyncManager_prediction_missed)
	SyncManager.skip_ticks_flagged.connect(_on_SyncManager_skip_ticks_flagged)
	SyncManager.remote_state_mismatch.connect(_on_SyncManager_remote_state_mismatch)
	SyncManager.peer_pinged_back.connect(_on_SyncManager_peer_pinged_back)
	SyncManager.state_loaded.connect(_on_SyncManager_state_loaded)
	SyncManager.tick_finished.connect(_on_SyncManager_tick_finished)

func create_debug_overlay(overlay_instance = null) -> void:
	if _debug_overlay != null:
		_debug_overlay.queue_free()
		_canvas_layer.remove_child(_debug_overlay)
	
	if overlay_instance == null:
		overlay_instance = DebugOverlay.instantiate()
	if _canvas_layer == null:
		_canvas_layer = CanvasLayer.new()
		add_child(_canvas_layer)
	
	_debug_overlay = overlay_instance
	_canvas_layer.add_child(_debug_overlay)

func show_debug_overlay(_visible: bool = true) -> void:
	if _visible and not _debug_overlay:
		create_debug_overlay()
	if _debug_overlay:
		_debug_overlay.visible = _visible

func hide_debug_overlay() -> void:
	if _debug_overlay:
		show_debug_overlay(false)

func is_debug_overlay_shown() -> bool:
	if _debug_overlay:
		return _debug_overlay.visible
	return false

func _on_SyncManager_skip_ticks_flagged(count: int) -> void:
	print ("-----")
	print ("Skipping %s local tick(s) to adjust for peer advantage" % count)

func _on_SyncManager_prediction_missed(tick: int, peer_id: int, local_input: Dictionary, remote_input: Dictionary) -> void:
	print ("-----")
	print ("Prediction missed on tick %s for peer %s" % [tick, peer_id])
	print ("Received input: %s" % SyncManager.sync_booster.serialize(remote_input))
	print ("Predicted input: %s" % SyncManager.sync_booster.serialize(local_input))
	
	if _debug_overlay:
		_debug_overlay.add_message(peer_id, "%s: Rollback %s ticks" % [tick, SyncManager.rollback_ticks])

func _on_SyncManager_rollback_flagged(tick: int) -> void:
	print ("-----")
	print ("Rolling back to tick %s (rollback %s tick(s))" % [tick, SyncManager.rollback_ticks])

func _on_SyncManager_remote_state_mismatch(tick: int, peer_id: int, local_hash: int, remote_hash: int) -> void:
	print ("-----")
	print ("On tick %s, remote state (%s) from %s doesn't match local state (%s)" % [tick, remote_hash, peer_id, local_hash])
	
	if _debug_overlay:
		_debug_overlay.add_message(peer_id, "%s: State mismatch" % tick)

func _on_SyncManager_peer_pinged_back(peer: SyncManager.Peer) -> void:
	print ("-----")
	print ("Peer %s: RTT %s ms | local lag %s | remote lag %s | advantage %s" % [peer.peer_id, peer.rtt, peer.local_lag, peer.remote_lag, peer.calculated_advantage])
	if _debug_overlay:
		_debug_overlay.update_peer(peer)

func _on_SyncManager_state_loaded(rollback_ticks: int) -> void:
	pass

func _on_SyncManager_tick_finished(is_rollback: bool) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		var action_pressed = event.is_action_pressed("sync_debug")
		if action_pressed:
			if not _debug_pressed:
				_debug_pressed = true
				show_debug_overlay(not is_debug_overlay_shown())
		else:
			_debug_pressed = false
