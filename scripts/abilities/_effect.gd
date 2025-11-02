extends RefCounted
class_name Effect

@export var duration: float = 2.0
@export var strength: float = 10.0
@export var type: Type = Type.NONE
@export var damage_type: OC.DAMAGE_TYPE = OC.DAMAGE_TYPE.MAGICAL

enum Type {
	NONE,
	# Control
	ROOT,
	SLOW,
	STUN,
	SILENCE,

	# Debuffs
	DAMAGE_OVER_TIME,
	DEBUFF_ARMOR,
	DEBUFF_DAMAGE,
	DEBUFF_MAGIC_RESIST,
	DEBUFF_SPEED,
	
	# Buffs
	BUFF_ARMOR,
	BUFF_DAMAGE,
	BUFF_MAGIC_RESIST,
	BUFF_SPEED,
	HEAL_OVER_TIME,
	SHIELD
}
