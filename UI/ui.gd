extends Control

@onready var settings_menu = $SettingsMenu


func _process(delta):
	# Handle the player pause action, which opens the settings page
	if Input.is_action_just_pressed("player_pause"):
		if settings_menu.visible:
			settings_menu.hide()
		else:
			settings_menu.show()
