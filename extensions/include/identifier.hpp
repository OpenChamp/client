#pragma once

#include <godot_cpp/classes/object.hpp>

namespace godot {

class Identifier : public Object {
	GDCLASS(Identifier, Object)

private:
	String group;
	String name;

	bool valid = false;

protected:
	static void _bind_methods();

public:
	Identifier();
	~Identifier();

	static Identifier* from_string(String _id_string);
	static Identifier* from_values(String _group, String _name);

	String get_group() const;
	String get_name() const;
};

} //namespace godot
