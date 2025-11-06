extends Healthbar

@export var after_effect: ColorRect;

#reduction in the bar's width per second. 0.8 is 80% of the bar per second
@export var after_effect_reduce_rate: float = 0.8;
@export var lines: Control;
var _after_effect_health: float;
var _after_effect_start_width: float;
var _last_max_health: float = -1.0;  # Track previous max_health to detect changes

func _ready() -> void:
	super();
	assert(after_effect != null);
	assert(lines != null);
	_after_effect_health = health;
	_after_effect_start_width = after_effect.size.x;
	_last_max_health = max_health;
	_rebuild_lines();

func _process(delta: float) -> void:
	_resize_after_effect();
	if _after_effect_health > health:
		_after_effect_health -= (max_health * after_effect_reduce_rate) * delta;
	else:
		_after_effect_health = health;

func set_health(h: float) -> void:
	super(h);
	# Only rebuild lines if max_health changed
	if _last_max_health != max_health:
		_rebuild_lines();
	
func set_max_health(mh: float) -> void:
	super(mh);
	_last_max_health = mh;
	_rebuild_lines();

func _rebuild_lines() -> void:
	
	#first remove all the already existing lines before making new ones
	for line in lines.get_children():
		line.queue_free();
		
	#we want a line every 100 hp
	var amount_of_lines: int = int(max_health / 100.0);
	var distance_between_lines: float = _foreground_start_width / float(amount_of_lines);
	var current_distance: float = 0.0;
	for i in amount_of_lines:

		#skip the first line
		if i == 0:
			current_distance += distance_between_lines;
			continue;

		#is the current health closer than the current distance?
		if floor((health / max_health) * _foreground_start_width) <= current_distance:
			break;
			
		# else, check what height of the line we want
		var line_height: float = 4.0;
		if (i % 10) == 0:
			#on every 1000 hp we want a higher line
			line_height = 8.0;
		
		#create the line
		var line: ColorRect = ColorRect.new();
		line.size = Vector2(1.0, line_height);
		line.position = Vector2(current_distance, 0.0);
		line.color = Color.BLACK;
		lines.add_child(line);
		
		current_distance += distance_between_lines;
		
func _resize_after_effect() -> void:
	if(max_health != 0.0):
		after_effect.size.x = (_after_effect_health / max_health) * _after_effect_start_width;
	else:
		after_effect.size.x = _after_effect_start_width;
