class_name Identifier extends Object

@export var group: String
@export var name: String


func _to_string():
    return group + ":" + name


func _init(_group: String, _name: String):
    if _group == "":
        _group = "openchamp"

    if _name == "":
        push_error("Identifier name cannot be empty")
        return

    group = _group
    name = _name
    

static func from_string(id_string: String) -> Identifier:
    var _group:String = "openchamp"
    var _name:String = id_string
    
    if id_string.contains(":"):
        var parts = id_string.split(":")
        _group = parts[0]
        _name = parts[1]

    return Identifier.new(_group, _name)
