extends Object
class_name RegistryBase

## RegistryBase is the base class for all registry classes. It provides the basic
## functionality for a registry class.
## Be warned that this class is not meant to be used directly, but rather to be
## an abstract base class.
## It also doesn't contain any internal data stroage options, since these might
## vary greatly between different registry classes.

var _json_type: String = ""


func _init():
    pass


func contains(_item: String) -> bool:
    return false


func get_element(_item: String):
    return null


func load_from_json(_json: Dictionary) -> bool:
    return false


func assure_validity():
    pass


# The following functions aren't meant to be overwriten by subclasses, but rather
# to be used by them and external code directly.


func get_json_type() -> String:
    return _json_type


func can_load_from_json(_json: Dictionary) -> bool:
    return _json_type == _json["type"]
