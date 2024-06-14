#pragma once

# include "base_include.hpp"

namespace godot {

class GDE_EXPORT Identifier : public Object {
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
	static Identifier* for_resource(String _resource_path);

	static String get_content_type_from_resouce(String _name);
	static String get_resource_prefix_from_type(String _name);

	String get_content_type() const;
	String get_content_prefix() const;

	Identifier* get_content_identifier() const;

	String get_group() const;
	String get_name() const;

	bool is_valid() const;
	
	String to_string() const;
	bool is_texture() const;
};

} //namespace godot
