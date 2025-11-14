## RELIES ON ECS SYSTEM
class_name InputOutputManager
extends Node

var game_root : Node = null
var nav_map : RID = RID()

func initialize():
	_cache_game_root_and_nav_map()
	get_tree().connect("node_added", Callable(self, "_on_node_added"))

func _cache_game_root_and_nav_map():
	game_root = get_tree().get_first_node_in_group("game_root")
	var nav_map_root : NavigationRegion3D = get_tree().get_first_node_in_group("map_root")
	if nav_map_root:
		nav_map = nav_map_root.get_navigation_map()
	else:
		nav_map = RID()

func _on_node_added(node):
	# If the game root is added after this manager, re-cache
	if node.is_in_group("game_root"):
		_cache_game_root_and_nav_map()

func get_gameroot() -> Node:
	if not game_root:
		_cache_game_root_and_nav_map()
	if not game_root:
		push_error("IOManager failed to obtain GameRoot")
		_notify_user("Game root not found. Please restart or check scene setup.")
	return game_root

func get_navmap() -> RID:
	if nav_map == RID():
		_cache_game_root_and_nav_map()
	if nav_map == RID():
		push_error("IOManager failed to obtain NavigationMap3D")
		_notify_user("Navigation map not found. Please restart or check scene setup.")
	return nav_map

@rpc("any_peer")
func move_champion(to: Vector3):
	pass;
	## Verification
	#if not multiplayer.is_server(): return
	#if nav_map == RID():
		#nav_map = get_navmap()
		#if nav_map == RID():
			#_notify_user("Navigation map not available. Movement aborted.")
			#return
	#if not game_root:
		#game_root = get_gameroot()
		#if not game_root:
			#_notify_user("Game root not available. Movement aborted.")
			#return
	## Entity lookup
	#var id = multiplayer.get_remote_sender_id()
	#var champ = _find_champion_node(id)
	#if champ == null:
		#push_error("Failed to find champion")
		#_notify_user("Champion node not found for id %s" % id)
		#return
	## ECS Component Update
	#if not ECS.entities.has(champ):
		#push_error("Champion entity not found in ECS")
		#_notify_user("Champion entity not found in ECS for node %s" % champ.name)
		#return
	#var movement = ECS.entities[champ].get_component("Movement_Component")
	#if movement == null:
		#push_error("Movement_Component not found for champion")
		#_notify_user("Movement_Component missing for champion %s" % champ.name)
		#return
	#movement.final_destination = to
	#movement.path = PackedVector3Array()
	#movement.current_path_index = -1

func _find_champion_node(id) -> Node3D:
	var entities_node = game_root.get_node_or_null("Entities")
	if entities_node:
		var champ = entities_node.get_node_or_null(str(id))
		if champ:
			return champ
	return null

func _notify_user(message: String):
	# Placeholder for user notification (UI popup, log, etc.)
	print("[IOManager] ", message)
