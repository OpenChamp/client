# Item specification

There is only one item class all specific items are prodived by data.
The item data is specified using a json file containing all items.

## Items json format


## Example item json file

```json
{
    "format_version": 1,
    "item_list": [
        {
            "id": "basic_sword",
            "texture": "item/sword.png",
            "recipe": {
                "gold": 500,
                "components": []
            },
            "stats": {
                "attack_damage": 10
            }
        },
        {
            "id": "basic_dagger",
            "texture": "item/dagger.png",
            "recipe": {
                "gold": 500,
                "components": []
            },
            "stats": {
                "attack_speed": 10
            }
        }
        {
            "id": "bastard_sword",
            "texture": "item/big_sword.png",
            "recipe": {
                "gold": 500,
                "components": [
                    "basic_sword",
                    "basic_sword",
                    "basic_dagger"
                ]
            },
            "stats": {
                "attack_damage": 40,
                "attack_speed": 15,
                "movement_speed": -5
            },
            "effects": [
                {
                    "base_id": "on_hit_attack",
                    "display_id": "bastard_sword_hit_effect",
                    "damage_type": "physical",
                    "effected_entities": "all"
                    "value": [
                        {
                            "id": "flat",
                            "value": 5
                        },
                        {
                            "id": "stat_scaled_percent",
                            "stat":"attack_damage",
                            "amount": 100
                        }
                    ]
                }
            ]
        }
    ]
}
```
