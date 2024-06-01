extends Control

@onready var settings_menu = $SettingsMenu
@onready var champions = $"../Champions"
@onready var stats = $Main/StatsInterface
@onready var champion: CharacterBody3D = null;

func _ready():
	settings_menu.hide()
	get_champion()

func _process(delta):
	if multiplayer.is_server(): return;
	if !champion:
		get_champion()
	# Handle the player pause action, which opens the settings page
	if Input.is_action_just_pressed("player_pause"):
		if settings_menu.visible:
			settings_menu.hide()
		else:
			settings_menu.show()
	
	if stats:
		check_stats()


func check_stats():
	if champion:
		stats.update_health(champion.get_health(), champion.get_health_max())
		stats.update_mana(champion.get_mana(), champion.get_max_mana())
		return
	stats.update_health(0) # If you can't find the champ they're probably dead


func get_champion():
	var id = multiplayer.get_unique_id()
	var champs = $"../Champions".get_children()
	for champ in champs:
		if str(champ.name) == str(id):
			champion = champ
			print("LETS GO!");
