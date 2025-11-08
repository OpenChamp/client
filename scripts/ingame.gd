# OpenChamp In-Game Logic Script
# Orchestrates game startup and lifecycle management
#
class_name GameRoot
extends Node
"""
Gameplay Lifecycle
1. [LOADING] Load game config, find out if you're a server or client, and connect to the server
2. [WAITING] Wait for the server to send the "start" signal (after all players have joined)
3. [PREGAME] Initialize game state and spawn players
	- Creates a 15s timer for spawn lock
	- Start the Minion Timer (30s)
	- During this time, players can see the map and their champions, but can't move or interact
5. [MATCH_START] Game starts, spawn lock ends
	- Players can move and interact
	- Players gain 100% movement speed for 15s
	- Minions should start spawning after 15s of movement
	- Game state updates every tick
"""

func _ready() -> void:
	print("GameRoot: Initializing in-game scene")
	# == Load Config == #
	var config = ConfigManager.get_ingame_configuration()
	print("GameRoot: Loaded in-game configuration: %s" % str(config))
	# == Connect to Server == #
	if config["network"]["server_ip"] != "":
		print("GameRoot: Connecting to server at %s" % config["network"]["server_ip"])
	else:
		print("GameRoot: No server IP provided, quitting")
		get_tree().quit()