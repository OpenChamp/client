# Effects

This is not about visual effects but about action effects.
In this category everything from passive stat boosts, on_hit or ability effects are described.
All of these are described using a data driven fromat, in other words more json.
This is the spec for the generic base effects that can be reused across several systems (champion passives, items, augments, ...).
Effects are purely functional and only possess the information passed to them when they are called.

When specifying an effect the json fields are very diverse.
The common fields always available are:

* `"base_id"` (required string) -> The id of the effect tha shall be used
* `"display_id"` (required string) -> The translation id is used to get a unique name and texture.
* `"is_exclusive"` (opional bool default true) -> If this is true the effect may only exist once per champion. For this exclusivity the display_id is used.

## Effect triggers

Every effect can be triggered by a set of events.
At the moment the following event types exist and every effect might do something on any of them:

* on_auto_attack_cast (caster, direction)
* on_auto_attack_hit (caster, hit_target, target_type)
* on_ability_cast (caster, direction, ability_type)
* on_ability_hit (caster, hit_target, target_type)

These are important when implementing each effect as they specify the information the effect has about the game during each condition.

## Scaling System

The value of certain effects needs to be set depending on other values.
For this the scalings exist.
The following scaling types exist:

* flat
* level_scaled
* stat_scaled

To specify a value multiple scaling options may be combined.
The values returned by individual scaling are then added to provide the final result.

### flat

Flat is just a flat value, that's it.
It only allows specifying the `value` when using it.
The resulting value is always the given value.

### level_scaled

As you might expect level_scaled, scales a value depending on the level.
It has the following parameters in json:

* `"min_value"` (required float) -> The value returned if the source is at level 1
* `"max_value"` (required float) -> The value returned if the source is at the max level
* `"source"` (optinal default: `"caster"`) -> Either "caster" or "target", specifies by whose level it gets scaled.
* `"interpolation"` (optinal default: `"linear"`) -> Either "liner" or "exponential", specifies how the values are interpolated between "min_value" and "max_value".

### stat_scaled

Scales the value by a stat.
These are different from the item stats since some more conditions might be required.

* health_max
* health_regen
* health_current
* mana_max
* mana_regen
* mana_current
* armor
* attack_damage
* attack_speed
* movement_speed

The following json fields exist:

* `"stat"` (required string) -> one of the stats above to specify the scaling
* `"source"` (optinal default: `"caster"`) -> Either "caster" or "target", specifies by whose level it gets scaled.
* `"amount"` (required float) -> how many percent of the stat should be returned as the value

### Example scaling json

```json
{
    "value": [
        {
            "id": "flat",
            "value": 5
        },
        {
            "id": "stat_scaled",
            "stat":"attack_damage",
            "amount": 75
        }
    ]
}
```

The total value returned by this will be `5 + (75% attack_damage)`.
This provides all the flexibility that might be required for all kind of stats.

## Existing Effects

At the moment the following effects exist:

* on_hit_attack
