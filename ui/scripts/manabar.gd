extends ProgressBar

@onready var champion:CharacterBody3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !champion:
		if !$"../..".champion:
			return
		champion = $"../..".champion
	else:
		max_value = champion.max_mana
		value = champion.mana
