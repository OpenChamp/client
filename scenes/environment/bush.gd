extends Area3D

func _on_body_entered(body):
	body.hide()
	body.get_node("Healthbar").hide()
	pass # Replace with function body.

func _on_body_exited(body):
	body.show()
	body.get_node("Healthbar").hide()
	pass # Replace with function body.
