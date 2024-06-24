#include "identifier.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Identifier::_bind_methods() {
	ClassDB::bind_static_method("Identifier", D_METHOD("from_string", "_id_string"), &Identifier::from_string);
	ClassDB::bind_static_method("Identifier", D_METHOD("from_values", "_group", "_name"), &Identifier::from_values);
	ClassDB::bind_static_method("Identifier", D_METHOD("for_resource", "_resource_path"), &Identifier::for_resource);

	ClassDB::bind_static_method("Identifier", D_METHOD("get_content_type_from_resouce", "_name"), &Identifier::get_content_type_from_resouce);
	ClassDB::bind_static_method("Identifier", D_METHOD("get_resource_prefix_from_type", "_name"), &Identifier::get_resource_prefix_from_type);
	
	ClassDB::bind_method(D_METHOD("get_group"), &Identifier::get_group);
	ClassDB::bind_method(D_METHOD("get_name"), &Identifier::get_name);
	ClassDB::bind_method(D_METHOD("is_valid"), &Identifier::is_valid);
	ClassDB::bind_method(D_METHOD("to_string"), &Identifier::to_string);
	ClassDB::bind_method(D_METHOD("get_content_type"), &Identifier::get_content_type);
	ClassDB::bind_method(D_METHOD("get_content_prefix"), &Identifier::get_content_prefix);
	ClassDB::bind_method(D_METHOD("get_content_identifier"), &Identifier::get_content_identifier);
	ClassDB::bind_method(D_METHOD("is_texture"), &Identifier::is_texture);
}

Identifier::Identifier() {}

Identifier::~Identifier() {}

String Identifier::get_group() const {
	return group;
}

String Identifier::get_name() const {
	return name;
}

bool Identifier::is_valid() const {
	return valid;
}

String Identifier::get_content_type() const{
	String content_type = get_name().split("/")[0];
	return content_type;
}

String Identifier::get_content_prefix() const{
	String type = get_content_type();
	return get_resource_prefix_from_type(type);
}

Identifier* Identifier::get_content_identifier() const{
	String corrected_name = get_name().replace(get_content_type() + "/", "");
	return Identifier::from_values(get_group(), corrected_name);
}

bool Identifier::is_texture() const{
	String content_type = get_content_type();
	return content_type == "textures";
}

String Identifier::to_string() const {
	String combined = group;
	combined += ":";
	combined += name;
	return combined;
}

String Identifier::get_content_type_from_resouce(String _name){
	if (!_name.contains("://")){
		return "";
	}

	String prefix = _name.split("://")[0];
	if (prefix == "dyn"){
		return "dynamic";
	}

	if (prefix == "texture"){
		return "textures";
	}

	if (prefix == "font"){
		return "fonts";
	}

	if (prefix == "material"){
		return "materials";
	}

	if (prefix == "model"){
		return "models";
	}

	if (prefix == "gamemode"){
		return "patchdata";
	}

	return "";
}

String Identifier::get_resource_prefix_from_type(String _name){
	if (_name == "textures"){
		return "texture://";
	}

	if (_name == "fonts"){
		return "font://";
	}

	if (_name == "materials"){
		return "material://";
	}

	if (_name == "models"){
		return "model://";
	}

	if (_name == "patchdata"){
		return "gamemode://";
	}

	return "dyn://";
}

Identifier* Identifier::from_string(String _id_string) {
	String group = "openchamp";
	String name = _id_string;

	int colon = _id_string.find(":");
	if (colon != -1){
		group = _id_string.substr(0, colon);
		name = _id_string.substr(colon + 1);
	}

	return Identifier::from_values(group, name);
}

Identifier* Identifier::from_values(String _group, String _name) {
	if (_group == ""){
		_group = "openchamp";
	}
	
	Identifier* id = memnew(Identifier);
	id->group = _group;
	id->name = _name;

	if (_name == "") {
		return nullptr;
	}

	id->valid = true;
	
	return id;
}

Identifier* Identifier::for_resource(String _resource_path) {
	String content_type = get_content_type_from_resouce(_resource_path);
	if (content_type == ""){
		return nullptr;
	}
	String prefix = get_resource_prefix_from_type(content_type);

	Identifier* id = Identifier::from_string(_resource_path.replace(prefix, ""));
	if (id == nullptr){
		return nullptr;
	}

	if (content_type != "dynamic"){
		id->name = content_type + "/" + id->name;
	}
	
	return id;
}
