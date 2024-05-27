extends Control

@onready var settings_menu = $SettingsMenu

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Handle the player pause action, which opens the settings page
	if Input.is_action_just_pressed("player_pause"):
		if settings_menu.visible:
			settings_menu.hide()
		else:
			settings_menu.show()
	
