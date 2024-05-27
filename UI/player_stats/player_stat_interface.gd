extends Control

@onready var healthbar = $ColorRect/BoxContainer/Health
@onready var manabar = $ColorRect/BoxContainer/Mana
@onready var expbar = $ColorRect/BoxContainer/Experience


func update_health(hp : int, max_hp : int = -1):
	healthbar.value = hp
	if max_hp == -1: return  # Only modify the hp
	healthbar.max_value = max_hp


func update_mana(mp : int, max_mp : int = -1):
	manabar.value = mp
	if max_mp == -1: return
	manabar.max_value = max_mp
	


func update_xp(xp : int, max_xp : int = -1):
	expbar.value = xp
	if max_xp == -1: return
	expbar.max_value = max_xp
