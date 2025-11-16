extends MeshInstance3D

@export var healthbar: Healthbar;
@export var offset_x: float = -100.0;
@export var height: float = 0.25;

func _ready():
	assert(healthbar != null);
	GameManager.camera_changed.connect(_on_game_manager_camera_changed)

func _process(delta: float) -> void:
	if GameManager.player_camera == null:
		return;
	
	healthbar.position = GameManager.player_camera.unproject_position(position + Vector3(0, height, 0)) + Vector2(offset_x, 0.0);

func _on_game_manager_camera_changed():
	# Camera reference is automatically updated in GameManager.player_camera
	pass
