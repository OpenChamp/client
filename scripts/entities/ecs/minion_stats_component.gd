## Stats Component - Handles health, mana, and stat management
class_name MinionStatsComponent
extends Component

## === Core Stats === ##
@export var max_health: float   = 100
@export var health: float      = 100
@export var max_mana: float     = 100
@export var mana: float        = 100
@export var move_speed: float = 5.0
@export var required_exp: float = 100.0
@export var addition_exp_per_level: float = 100.0
@export var current_exp: float = 0.0
@export var level: int = 1
## === Offensive Stats === ##
@export var attack_range: float = 1.0 ## In units
@export var attack_speed: float = 1.0 ## Attacks per second
@export var auto_damage_type: OC.DAMAGE_TYPE = OC.DAMAGE_TYPE.PHYSICAL
@export var crit_chance: float = 0.0 ## Percentage chance to crit
@export var crit_bonus: int = 0 ## Flat bonus damage on crit
@export var true_bonus: int = 0 ## Flat bonus true damage on hit
@export var magic_power: float = 1.0 # Flat Magic Damage
@export var physical_power: float = 1.0 # Flat Physical Damage
@export var projectile_speed: float = 5.0
## === Defensive Stats === ##
@export var armor: int = 0# Percentage physical damage reduction
@export var magic_resist: int = 0# Percentage magic damage reduction
@export var dodge: int = 0# Percentage chance to dodge
## === Scaling & Utility Stats === ##
@export var health_regen: float = 1.0# Health regenerated per second
@export var mana_regen: float = 1.0# Mana regenerated per second
@export var life_steal: float = 0.0# Percentage of physical damage dealt returned as health
@export var spell_vamp: float = 0.0# Percentage of magic damage dealt returned as health
@export var omni_vamp: float = 0.0# Percentage of damage dealt returned as health
@export var leech: float = 0.0# Percentage of damage dealt returned as mana
@export var resistance: float = 0.0# Percentage damage reduction
@export var vision_range: float = 5.0# Vision range in units

## Signals
signal health_changed(new_health: float, max_health: float)
signal mana_changed(new_mana: float, max_mana: float)
signal death

func _init(base_stats: Dictionary = {}) -> void:
	for stat_name in base_stats:
		if has_meta(stat_name):
			set(stat_name, base_stats[stat_name])
		else:
			set(stat_name, base_stats[stat_name])

func on_ready() -> void:
	# Full health on spawn
	health = max_health
	mana = max_mana

func on_process(delta: float) -> void:
	# Health regeneration
	if health < max_health and health_regen > 0:
		health += health_regen * delta
		if health > max_health:
			health = max_health
		health_changed.emit(health, max_health)
	
	# Mana regeneration
	if mana < max_mana and mana_regen > 0:
		mana += mana_regen * delta
		if mana > max_mana:
			mana = max_mana
		mana_changed.emit(mana, max_mana)

func on_damage_taken(damage: int, damage_type: OC.DAMAGE_TYPE) -> void:
	var reduced_damage = damage
	
	match damage_type:
		OC.DAMAGE_TYPE.PHYSICAL:
			reduced_damage = int(damage * (1.0 - float(armor) / 100.0))
		OC.DAMAGE_TYPE.MAGICAL:
			reduced_damage = int(damage * (1.0 - float(magic_resist) / 100.0))
		OC.DAMAGE_TYPE.TRUE:
			reduced_damage = damage
	
	health -= reduced_damage
	health_changed.emit(health, max_health)
	
	if health <= 0:
		health = 0
		death.emit()

func apply_healing(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health
	health_changed.emit(health, max_health)

func get_damage_multiplier(damage_type: OC.DAMAGE_TYPE) -> float:
	match damage_type:
		OC.DAMAGE_TYPE.PHYSICAL:
			return 1.0 - float(armor) / 100.0
		OC.DAMAGE_TYPE.MAGICAL:
			return 1.0 - float(magic_resist) / 100.0
		OC.DAMAGE_TYPE.TRUE:
			return 1.0
		_:
			return 1.0

func is_alive() -> bool:
	return health > 0
