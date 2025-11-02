extends StaticBody3D
class_name Structure

## === Core Stats === ##
@export var team : int        = 1
@export var max_health : int   = 1000
@export var health : int      = 100
## === Offensive Stats === ##
@export var attack_range : float = 1.0 ## In units
@export var attack_speed : float = 1.0 ## Attacks per second
@export var damage_per_tick : float = 1.0 ## Damage dealt per tick
@export var ticks_under_tower : int = 10 ## Number of ticks an entity must stay under tower to take damage
## === Defensive Stats === ##
@export var armor: int = 0;
@export var magic_resist: int = 0;
@export var resistance: float = 0.0;
@export var dodge: int = 0;
## === Scaling & Utility Stats === ##
@export var health_regen: float = 1.0;

func _ready() -> void:
    pass;