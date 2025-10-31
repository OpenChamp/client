extends Node

class_name FogOfWar

@export var vision_range: float = 10.0

var local_player: Node3D = null
var all_entities := []
@onready var fog_mask_rect : ColorRect = null
@onready var camera : Camera3D = null
var mask_radius_px: float = 1.0 # Will scale with range and camera zoom if desired

func _ready() -> void:
	# Find all champion entities
	get_tree().connect("node_added", Callable(self, "_on_node_added"))
	set_process(true)
	fog_mask_rect = get_node_or_null("FogCanvas/FogMask")
	var cams = get_tree().get_nodes_in_group("cameras")
	if cams.size() > 0:
		camera = cams[0] # Assumes main gameplay camera

func _on_node_added(node):
	if node.is_class("OC_Entity") and node not in all_entities:
		all_entities.append(node)
		# Optionally connect for deletion

func _process(_delta):
	if Util.dedicated_server: queue_free(); 
	if local_player == null:
		_update_local_player()
	if local_player == null or fog_mask_rect == null or camera == null:
		return
		
	var dist = local_player.global_transform.origin.distance_to(local_player.global_transform.origin)
	local_player.visible = dist <= vision_range
	# --- Visual Mask Update ---
	var screen_pos = camera.unproject_position(local_player.global_transform.origin)
	if screen_pos:
		var m: ShaderMaterial = fog_mask_rect.material
		m.set_shader_parameter("circle_center", screen_pos)
		m.set_shader_parameter("circle_radius", mask_radius_px)

func _update_local_player():
	var my_id = multiplayer.get_unique_id()
	local_player = get_tree().get_first_node_in_group("game_root").get_node(str(my_id))
