extends Control

@onready var settings_menu = $SettingsMenu
@onready var champions = $"../Champions"
@onready var stats = $CenterContainer/PlayerStatInterface
@onready var champion: CharacterBody3D = null;

func _ready():
	get_champion()

func _process(delta):
	if !champion:
		get_champion()
	# Handle the player pause action, which opens the settings page
	if Input.is_action_just_pressed("player_pause"):
		if settings_menu.visible:
			settings_menu.hide()
		else:
			settings_menu.show()
	
	check_stats()

func check_stats():
	var pid = multiplayer.get_unique_id()
	for child in champions.get_children():
		if child.name == str(pid):
			stats.update_health(child.health, child.max_health)
			stats.update_mana(child.mana, child.max_mana)
			# stats.update_xp() I'll leave this for when an xp system is made
			return
	stats.update_health(0) # If you can't find the champ they're probably dead

func get_champion():
	var id = multiplayer.get_unique_id()
	var champs = $"../Champions".get_children()
	for champ in champs:
		if champ.pid == id:
			champion = champ
			print("LETS GO!");
