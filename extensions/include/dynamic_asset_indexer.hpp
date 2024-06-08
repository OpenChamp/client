#pragma once

#include "godot_cpp/classes/object.hpp"
#include "godot_cpp/templates/hash_map.hpp"
#include "identifier.hpp"

namespace godot {

class DynamicAssetIndexer : public Object {
	GDCLASS(DynamicAssetIndexer, Object)

private:
    HashMap<String, String> asset_map;
	bool files_indexed = false;

protected:
	static void _bind_methods();

public:
	DynamicAssetIndexer();
	~DynamicAssetIndexer();
	
	void index_files();
	String get_asset_path(Identifier* asset_id);

	void dump_asset_map();
	Variant get_asset_map();
};

} //namespace godot
