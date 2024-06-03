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
	var min = (t-sec)/60
	if min < 10:
		min = "0" + str(min)
	text = str(min) + ":" + str(sec)
