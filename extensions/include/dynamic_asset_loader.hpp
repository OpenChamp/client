#pragma once

#include "godot_cpp/classes/object.hpp"
#include "godot_cpp/templates/hash_map.hpp"

namespace godot {

class DynamicAssetLoader : public Object {
	GDCLASS(DynamicAssetLoader, Object)

private:
    HashMap<String, String> asset_map;

protected:
	static void _bind_methods();

public:
	DynamicAssetLoader();
	~DynamicAssetLoader();

	void dump_asset_map();
};

} //namespace godot
