extends Node

var websocket_url := "ws://localhost:8080/ws"
# Pretending Vars are Globals for a moment
@onready var chat_manager := $"ChatManager(global)"
@onready var WSManager := $"WSManager(global)"

# Graphing Variables
@onready var sent_line: Line2D = $Node2D/Sent
@onready var received_line: Line2D = $Node2D/Received
var sent_data: Array[Vector2] = []
var received_data: Array[Vector2] = []
const MAX_POINTS = 100 
var elapsed_time: float = 0.0
var second_ahead: float = 0.0
var total_sent_packets = 0
var total_received_packets = 0
var last_username: String

@onready var sent_node := $UI/Control/PanelContainer/VBoxContainer/HBoxContainer/PacketsSent
@onready var received_node := $UI/Control/PanelContainer/VBoxContainer/HBoxContainer2/PacketsReceived

# Detailed Network Statistics
var sent_bytes: int = 0
var received_bytes: int = 0
var sent_packets_per_second: Array[int] = []
var received_packets_per_second: Array[int] = []
var current_second_sent: int = 0
var current_second_received: int = 0
var last_second_time: float = 0.0
var peak_sent_pps: int = 0
var peak_received_pps: int = 0
var current_sent_pps: int = 0
var current_received_pps: int = 0
var connection_start_time: float = 0.0
var disconnections: int = 0
var failed_messages: int = 0

# Dynamic chat timer management
var active_chat_timers: Array[Debug_Chat_Timer] = []

class Debug_Chat_Timer:
	extends Timer
	var target: String
	var room: String
	var msg: String
	var parent_node: Node
	var is_send_mode: bool
	
	func send_chat_message() -> void:
		"""Sends global or private chat message and decreases wait time"""
		if room == "Global Chat":
			parent_node.chat_manager.send_chat_message(ChatManager.CHANNELS.GLOBAL_CHAT, msg)
		elif room == "Private Chat" and not target.is_empty():
			parent_node.chat_manager.send_chat_message(ChatManager.CHANNELS.PRIVATE_CHAT, msg, target)
		# Gradually decrease wait time (speed up)
		if wait_time > 0.01:
			wait_time -= 0.01
	
	func receive_chat_message() -> void:
		"""Simulates receiving a chat message and decreases wait time"""
		if room == "Global Chat":
			print("Simulating received global chat: %s" % msg)
		elif room == "Private Chat":
			print("Simulating received private message from %s: %s" % [target, msg])
		
		# Gradually decrease wait time (speed up)
		if wait_time > 0.01:
			wait_time -= 0.01

func _ready() -> void:
	set_process(false)
	# Wait 1s so all of our "Global" variables are ready
	get_tree().create_timer(1.0).timeout.connect(func():
		connection_start_time = Time.get_ticks_msec() / 1000.0
		last_second_time = connection_start_time
		print("Beginning Network Test")
		# Required Signals
		WSManager.auth_required.connect(_on_auth_required)
		WSManager.auth_obtained.connect(_on_auth_obtained)
		WSManager.ws_disconnected.connect(func():
			get_tree().quit() # Just quit on disconnect for this test
		)
		WSManager.packet_received.connect(func(): 
			# total_received_packets += 1
			current_second_received += 1
		)
		WSManager.packet_sent.connect(func(): 
			# current_second_sent += 1
			total_sent_packets += 1
		)
		
		# chat_manager Setup
		chat_manager.chat_container = $UI/Control/ChatWidget/VBoxContainer/ChatLog
		chat_manager.packet_received.connect(func(payload): last_username = payload["username"])
		
		WSManager.chat_manager = chat_manager
		WSManager.connect_to_server(websocket_url)
		$Timer.start()
		$Timer2.start()
		set_process(true)
	)
	
func _physics_process(delta: float) -> void:
	elapsed_time += delta
	var current_time = Time.get_ticks_msec() / 1000.0 - connection_start_time
	
	# Check if a second has passed
	if current_time >= last_second_time + 1.0:
		# Store the PPS for this second
		current_sent_pps = current_second_sent
		current_received_pps = current_second_received
		
		# Update peak values
		peak_sent_pps = max(peak_sent_pps, current_sent_pps)
		peak_received_pps = max(peak_received_pps, current_received_pps)
		
		# Add to history
		sent_packets_per_second.append(current_sent_pps)
		received_packets_per_second.append(current_received_pps)
		
		# Keep history limited
		while sent_packets_per_second.size() > MAX_POINTS:
			sent_packets_per_second.remove_at(0)
			received_packets_per_second.remove_at(0)
		
		# Reset counters
		current_second_sent = 0
		current_second_received = 0
		last_second_time = current_time
		
		# Update graph with actual PPS data
		if sent_packets_per_second.size() > 0:
			sent_data.clear()
			received_data.clear()
			for i in range(sent_packets_per_second.size()):
				sent_data.append(Vector2(float(i), float(sent_packets_per_second[i])))
				received_data.append(Vector2(float(i), float(received_packets_per_second[i])))
		
		update_graph()

func update_graph():
	# 1. Normalize/Scale the data for the graph area
	var plot_points_sent = PackedVector2Array()
	var plot_points_received = PackedVector2Array()

	if sent_data.size() < 2:
		sent_line.points = plot_points_sent
		received_line.points = plot_points_received
		return

	# Determine the time offset for translation (this keeps the graph moving left)
	var time_offset = sent_data[0].x
	var graph_width = 500.0 # Adjust to your desired graph width in pixels
	var graph_height = 200.0 # Adjust to your desired graph height in pixels
	
	# Calculate dynamic Y scale based on max value in current data
	var max_packets = max(sent_data[-1].y, received_data[-1].y)
	max_packets = max(max_packets, 1.0)  # Avoid division by zero
	var y_scale = (graph_height * 0.9) / max_packets

	for i in range(sent_data.size()):
		var sent_point = sent_data[i]
		var received_point = received_data[i]

		# X position: time (minus offset) scaled to graph width
		var x_pos = (sent_point.x - time_offset) * (graph_width / float(MAX_POINTS))
		# Y position: scaled value (inverted because Y is down in 2D)
		var y_pos_sent = graph_height - (sent_point.y * y_scale) 
		var y_pos_received = graph_height - (received_point.y * y_scale)

		plot_points_sent.append(Vector2(x_pos, y_pos_sent))
		plot_points_received.append(Vector2(x_pos, y_pos_received))

	# 2. Update the Line2D nodes
	sent_line.points = plot_points_sent
	received_line.points = plot_points_received
	
	sent_node.text = _format_stats_label("Sent", true)
	received_node.text = _format_stats_label("Received", false)

	# You may need to add code here to draw axes, labels, and grid using the _draw() function
func _on_timer_timeout() -> void:
	chat_manager.send_chat_message(ChatManager.CHANNELS.GLOBAL_CHAT, " Hey Guys! ")
	if $Timer.wait_time > 0.01:
		$Timer.wait_time -= 0.01
	pass

func _on_timer_2_timeout() -> void:
	_on_button_button_up()
	
func _on_auth_required():
	WSManager.fast_registration(str("TestAccount", randi()))
	
func _on_auth_obtained():
	pass;

# ============ DETAILED STATISTICS FUNCTIONS ============

func _update_pps_stats() -> void:
	"""Deprecated: PPS now tracked per-second in _physics_process"""
	pass

func _format_stats_label(label: String, is_sent: bool) -> String:
	"""Formats the stats label with current PPS information"""
	var pps = current_sent_pps if is_sent else current_received_pps
	var total = total_sent_packets if is_sent else total_received_packets
	
	return "%s: %d\nCurrent PPS: %d" % [label, total, pps]

func get_detailed_stats() -> Dictionary:
	"""Returns comprehensive network statistics"""
	var uptime = Time.get_ticks_msec() / 1000.0 - connection_start_time
	var avg_sent_pps = total_sent_packets / max(uptime, 0.1)
	var avg_received_pps = total_received_packets / max(uptime, 0.1)
	
	return {
		"uptime_seconds": uptime,
		"total_sent_packets": total_sent_packets,
		"total_received_packets": total_received_packets,
		"total_sent_bytes": sent_bytes,
		"total_received_bytes": received_bytes,
		"avg_sent_pps": avg_sent_pps,
		"avg_received_pps": avg_received_pps,
		"peak_sent_pps": peak_sent_pps,
		"peak_received_pps": peak_received_pps,
		"disconnections": disconnections,
		"failed_messages": failed_messages,
		"total_data_exchanged_kb": (sent_bytes + received_bytes) / 1024.0
	}

func print_detailed_stats() -> void:
	"""Prints comprehensive network statistics to console"""
	var stats = get_detailed_stats()
	
	print("\n" + "=".repeat(50))
	print("DETAILED NETWORK STATISTICS")
	print("=".repeat(50))
	print("Uptime: %.2f seconds" % stats["uptime_seconds"])
	print("\nPackets:")
	print("  Sent: %d (Current: %d PPS, Peak: %d PPS)" % [
		stats["total_sent_packets"],
		current_sent_pps,
		stats["peak_sent_pps"]
	])
	print("  Received: %d (Current: %d PPS, Peak: %d PPS)" % [
		stats["total_received_packets"],
		current_received_pps,
		stats["peak_received_pps"]
	])
	print("\nData Transfer:")
	print("  Sent: %d bytes" % stats["total_sent_bytes"])
	print("  Received: %d bytes" % stats["total_received_bytes"])
	print("  Total Exchanged: %.2f KB" % stats["total_data_exchanged_kb"])
	print("\nErrors/Issues:")
	print("  Disconnections: %d" % stats["disconnections"])
	print("  Failed Messages: %d" % stats["failed_messages"])
	print("=".repeat(50) + "\n")


func _on_button_button_up() -> void:
	var channel_node : OptionButton = $UI/Control/PanelContainer2/VBoxContainer/Channel
	var type_node : OptionButton = $UI/Control/PanelContainer2/VBoxContainer/Type
	var user_node : LineEdit = $UI/Control/PanelContainer2/VBoxContainer/User
	var message_node : LineEdit = $UI/Control/PanelContainer2/VBoxContainer/Message
	
	var is_sending = type_node.get_selected_id() == 0  # 0 = Send, 1 = Receive
	var new_timer = Debug_Chat_Timer.new()
	new_timer.room = channel_node.get_item_text(channel_node.get_selected_id())
	new_timer.target = user_node.text
	new_timer.msg = message_node.text
	new_timer.parent_node = self
	new_timer.is_send_mode = is_sending
	new_timer.wait_time = 0.5  # Start with 0.5 second interval
	
	if is_sending:
		new_timer.timeout.connect(new_timer.send_chat_message)
	else:
		new_timer.timeout.connect(new_timer.receive_chat_message)
	
	# Add to tree and start
	add_child(new_timer)
	active_chat_timers.append(new_timer)
	new_timer.start()
	
	print("Started %s chat timer: room='%s', target='%s', msg='%s'" % [
		"send" if is_sending else "receive",
		new_timer.room,
		new_timer.target,
		new_timer.msg
	])
