#include "identifier.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Identifier::_bind_methods() {
	ClassDB::bind_static_method("Identifier", D_METHOD("from_string", "_id_string"), &Identifier::from_string);
	ClassDB::bind_static_method("Identifier", D_METHOD("from_values", "_group", "_name"), &Identifier::from_values);
	
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
	if (type == "textures"){
		return "texture://";
	}
	if (type == "fonts"){
		return "font://";
	}

	return "dyn://";
}

Identifier* Identifier::get_content_identifier() const{
	return Identifier::from_values(get_group(), get_name().replace(get_content_type() + "/", ""));
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
