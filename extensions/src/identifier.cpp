#include "identifier.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Identifier::_bind_methods() {
	ClassDB::bind_static_method("Identifier", D_METHOD("from_string", "_id_string"), &Identifier::from_string);
	ClassDB::bind_static_method("Identifier", D_METHOD("from_values", "_group", "_name"), &Identifier::from_values);
	
	ClassDB::bind_method(D_METHOD("get_group"), &Identifier::get_group);
	ClassDB::bind_method(D_METHOD("get_name"), &Identifier::get_name);
}

Identifier::Identifier() {}

Identifier::~Identifier() {}

String Identifier::get_group() const {
	return group;
}

String Identifier::get_name() const {
	return name;
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
