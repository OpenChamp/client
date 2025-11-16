class_name DetailedNetworkGrid
extends GridContainer

var stat_nodes : Array = []

var peerStatisticDictionary = {
	0: "Packet Loss (Mean)",
	1: "Packet Loss Variance",
	2: "Packet Loss Epoch",
	3: "RTT",
	4: "RTT Variance",
	5: "RTT (Last)",
	6: "RTT (Last Variance)",
	7: "Packet Throttle",
	8: "Packet Throttle Limit",
	9: "Packet Throttle Counter",
	10: "Packet Throttle Epoch",
	11: "Packet Throttle Acceleration",
	12: "Packet Throttle Decel",
	13: "Packet Throttle Interval"
}

@onready var label_settings : LabelSettings = LabelSettings.new()
func _ready():
	columns = 2
	label_settings.font_color = Color.WHITE
	label_settings.font_size = 12
	label_settings.outline_color = Color.BLACK
	label_settings.shadow_size = 3
	for stat:int in peerStatisticDictionary:
		var key_node = Label.new()
		key_node.name = str("Peer_Stat_", stat)
		key_node.text = peerStatisticDictionary[stat]
		var value_node = Label.new()
		value_node.text = "0.0"
		stat_nodes.append([key_node, value_node])
		# Apply Styling
		key_node.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_LEFT)
		value_node.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_RIGHT)
		key_node.custom_minimum_size = Vector2(50, 0)
		value_node.custom_minimum_size = Vector2(50, 0)
		key_node.label_settings = label_settings
		value_node.label_settings = label_settings
		add_child(key_node)
		add_child(value_node)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func update_stats(peer) -> void:
	if !peer: return;
	for index in stat_nodes.size():
		stat_nodes[index][1].text = str(NetworkManager.peer.get_statistic(index))
