# Game State Management #

class_name LifecycleSystem
extends Node

enum Phase {
	LOBBY,           # Players joining
	COUNTDOWN,       # 15s spawn lock countdown
	SPAWN_LOCK,      # First 15s of game
	EARLY_GAME,      # 0-10 min
	MID_GAME,        # 10-20 min
	LATE_GAME,       # 20+ min
	ENDING,          # Victory/Defeat sequence
	POST_GAME        # Stats screen
}

signal phase_changed(old_phase: Phase, new_phase: Phase)
signal phase_timer_updated(phase: Phase, time_remaining: float)

var current_phase: Phase = Phase.LOBBY
var phase_timers: Dictionary = {}
var phase_start_times: Dictionary = {}
