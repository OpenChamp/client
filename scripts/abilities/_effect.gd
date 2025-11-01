extends RefCounted
class_name Effect

@export var duration: float = 2.0
@export var strength: float = 10.0
@export var type: Type = Type.NONE

enum Type {
	NONE,
	DAMAGE_OVER_TIME,
	SLOW,
	STUN,
	HEAL_OVER_TIME
}
