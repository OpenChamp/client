extends Node

@onready var healthbar = $"../ChampionUI/HealthMana/HealthBar"
@onready var manabar = $"../ChampionUI/HealthMana/ManaBar"


func update_health(hp : int, max_hp : int = -1):
	healthbar.value = hp
	if max_hp == -1: return  # Only modify the hp
	healthbar.max_value = max_hp


func update_mana(mp : int, max_mp : int = -1):
	manabar.value = mp
	if max_mp == -1: return
	manabar.max_value = max_mp
