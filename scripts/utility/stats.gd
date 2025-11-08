class_name Stats
extends Resource
## === Audio Clips === ##
@export var hurt_sound: AudioStream
@export var death_sound: AudioStream
# Multiple attack sounds for variety
@export var attack_sound_1: AudioStream
@export var attack_sound_2: AudioStream
@export var attack_sound_3: AudioStream
## == Team & Identification == ##
@export var creature_id: int
@export var team: int = -1
@export var team_group: String 
## == Movement Configuration == #
@export var server_pos: Vector3
@export var target_pos: Vector3
@export var follow_distance: float = 2.0
@export var max_follow_time: float = 8.0
## == Combat Configuration == ##
@export var attack_cooldown: float = 1.0
@export var attack_timer: float = 0.0
var can_attack_now: bool = true
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
