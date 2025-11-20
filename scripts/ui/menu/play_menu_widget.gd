extends PanelContainer

@onready var PlayButton := $MarginContainer/VBoxContainer/Button
@onready var TrainingButton := $MarginContainer/VBoxContainer/Button2
@onready var ChampionsButton := $MarginContainer/VBoxContainer/Button3
@onready var InventoryButton := $MarginContainer/VBoxContainer/Button4
@onready var ProfileButton := $MarginContainer/VBoxContainer/Button5
@onready var SettingsButton := $MarginContainer/VBoxContainer/Button6
@onready var QuitButton := $MarginContainer/VBoxContainer/Button7

func _ready():
	PlayButton.pressed.connect(_on_play_pressed)
	TrainingButton.pressed.connect(_on_training_pressed)
	ChampionsButton.pressed.connect(_on_champions_pressed)
	InventoryButton.pressed.connect(_on_inventory_pressed)
	ProfileButton.pressed.connect(_on_profile_pressed)
	SettingsButton.pressed.connect(_on_settings_pressed)
	QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	# TODO: Implement play functionality
	pass
func _on_training_pressed():
	# TODO: Implement training functionality
	pass
func _on_champions_pressed():
	# TODO: Implement champions functionality
	pass
func _on_inventory_pressed():
	# TODO: Implement inventory functionality
	pass
func _on_profile_pressed():
	# TODO: Implement profile functionality
	pass
func _on_settings_pressed():
	# TODO: Implement settings functionality
	UIManager.show_overlay_interface("Settings")
	pass
func _on_quit_pressed():
	get_tree().quit()
