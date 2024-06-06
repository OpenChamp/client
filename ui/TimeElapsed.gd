extends RichTextLabel

var time_elapsed : float = 0;
# Called when the node enters the scene tree for the first time.
func _ready():
	time_elapsed = 0;
	pass # Replace with function body.


func _physics_process(delta):
	time_elapsed += delta;
	set_time(time_elapsed)

func set_time(t:int):
	var sec = t % 60
	var mins = int(t - sec)/60
	if mins < 10:
		mins = "0" + str(mins)
	text = str(mins) + ":" + str(sec)
