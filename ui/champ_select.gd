extends Control

func _ready() -> void:
	pass

func _on_ranger_champ_button_up() -> void:
	NetworkManager.select_champion("ranger")
	hide()
	pass # Replace with function body.
