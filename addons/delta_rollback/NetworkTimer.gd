extends Node
class_name NetworkTimer

@export var autostart := false
@export var one_shot := false
@export var wait_ticks := 0
@export var hash_state := true

var ticks_left := 0

var _paused: = false
var _running := false

signal timeout ()

func _ready() -> void:
	add_to_group('network_sync')
	SyncManager.sync_stopped.connect(_on_SyncManager_sync_stopped)
	if autostart:
		start()

func is_stopped() -> bool:
	return not _running

func start(ticks: int = -1) -> void:
	if ticks > 0:
		SyncManager.set_synced(self, "wait_ticks", ticks)
	SyncManager.set_synced(self, "ticks_left", wait_ticks)
	SyncManager.set_synced(self, "_running", true)
	SyncManager.set_synced(self, "_paused", false)

func stop():
	SyncManager.set_synced(self, "_running", false)
	SyncManager.set_synced(self, "ticks_left", 0)

func pause() -> void:
	SyncManager.set_synced(self, "_paused", true)

func unpause() -> void:
	SyncManager.set_synced(self, "_paused", false)

func _on_SyncManager_sync_stopped() -> void:
	stop()

func _network_process(_input: Dictionary) -> void:
	if not _running or _paused:
		return
	if ticks_left <= 0:
		SyncManager.set_synced(self, "_running", false)
		return
	
	SyncManager.set_synced(self, "ticks_left", ticks_left - 1)
	
	if ticks_left == 0:
		if not one_shot:
			SyncManager.set_synced(self, "ticks_left", wait_ticks)
		emit_signal("timeout")
