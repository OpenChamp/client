extends Object
class_name StatCollection

@export var health_max: int = 0
@export var health_regen: float = 0

@export var mana_max: int = 0
@export var mana_regen: float = 0

@export var armor: int = 0
@export var magic_resist: int = 0

@export var attack_damage: int = 0
@export var attack_speed: float = 0
@export var attack_range: float = 0
@export var attack_crit_chance: float = 0
@export var attack_crit_damage: float = 0

@export var movement_speed: float = 0


static func from_dict(json_data_object: Dictionary) -> StatCollection:
    var stat = StatCollection.new()
    if json_data_object.has("health_max"):
        stat.health_max = int(json_data_object["health_max"])

    if json_data_object.has("health_regen"):
        stat.health_regen = float(json_data_object["health_regen"])
    

    if json_data_object.has("mana_max"):
        stat.mana_max = int(json_data_object["mana_max"])

    if json_data_object.has("mana_regen"):
        stat.mana_regen = float(json_data_object["mana_regen"])
    

    if json_data_object.has("armor"):
        stat.armor = int(json_data_object["armor"])

    if json_data_object.has("magic_resist"):
        stat.magic_resist = int(json_data_object["magic_resist"])
    

    if json_data_object.has("attack_damage"):
        stat.attack_damage = int(json_data_object["attack_damage"])

    if json_data_object.has("attack_speed"):
        stat.attack_speed = float(json_data_object["attack_speed"])

    if json_data_object.has("attack_range"):
        stat.attack_range = float(json_data_object["attack_range"])

    if json_data_object.has("attack_crit_chance"):
        stat.attack_crit_chance = float(json_data_object["attack_crit_chance"])

    if json_data_object.has("attack_crit_damage"):
        stat.attack_crit_damage = float(json_data_object["attack_crit_damage"])
    

    if json_data_object.has("movement_speed"):
        stat.movement_speed = float(json_data_object["movement_speed"])
    
    return stat


func get_copy() -> StatCollection:
    var stat = StatCollection.new()
    stat.add(self)
    return stat


func add(other: StatCollection, times: int = 1):
    health_max += other.health_max * times
    health_regen += other.health_regen * times

    mana_max += other.mana_max * times
    mana_regen += other.mana_regen * times

    armor += other.armor * times
    magic_resist += other.magic_resist * times

    attack_damage += other.attack_damage * times
    attack_speed += other.attack_speed * times
    attack_range += other.attack_range * times
    attack_crit_chance += other.attack_crit_chance * times
    attack_crit_damage += other.attack_crit_damage * times
    
    movement_speed += other.movement_speed * times


func clamp_self(_min: StatCollection, _max: StatCollection):
    var new_vals = clamp(self, _min, _max)
    health_max = new_vals.health_max
    health_regen = new_vals.health_regen

    mana_max = new_vals.mana_max
    mana_regen = new_vals.mana_regen

    armor = new_vals.armor
    magic_resist = new_vals.magic_resist

    attack_damage = new_vals.attack_damage
    attack_speed = new_vals.attack_speed
    attack_range = new_vals.attack_range
    attack_crit_chance = new_vals.attack_crit_chance
    attack_crit_damage = new_vals.attack_crit_damage

    movement_speed = new_vals.movement_speed


func clamp_below(_max: StatCollection):
    clamp_self(StatCollection.new(), _max)


static func clamp(_stat: StatCollection, _min: StatCollection, _max: StatCollection) -> StatCollection:
    var stat = StatCollection.new()
    stat.health_max = clamp(_stat.health_max, _min.health_max, _max.health_max)
    stat.health_regen = clamp(_stat.health_regen, _min.health_regen, _max.health_regen)

    stat.mana_max = clamp(_stat.mana_max, _min.mana_max, _max.mana_max)
    stat.mana_regen = clamp(_stat.mana_regen, _min.mana_regen, _max.mana_regen)

    stat.armor = clamp(_stat.armor, _min.armor, _max.armor)
    stat.magic_resist = clamp(_stat.magic_resist, _min.magic_resist, _max.magic_resist)

    stat.attack_damage = clamp(_stat.attack_damage, _min.attack_damage, _max.attack_damage)
    stat.attack_speed = clamp(_stat.attack_speed, _min.attack_speed, _max.attack_speed)
    stat.attack_range = clamp(_stat.attack_range, _min.attack_range, _max.attack_range)
    stat.attack_crit_chance = clamp(_stat.attack_crit_chance, _min.attack_crit_chance, _max.attack_crit_chance)
    stat.attack_crit_damage = clamp(_stat.attack_crit_damage, _min.attack_crit_damage, _max.attack_crit_damage)

    stat.movement_speed = clamp(_stat.movement_speed, _min.movement_speed, _max.movement_speed)

    return stat


static func sum(stats: Array[StatCollection]) -> StatCollection:
    var result = StatCollection.new()
    for stat in stats:
        result.add(stat)
    return result
