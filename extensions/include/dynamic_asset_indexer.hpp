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

	static DynamicAssetIndexer* _AssetIndexerSingleton;

protected:
	static void _bind_methods();

public:
	static DynamicAssetIndexer* get_singleton() { 
		if (_AssetIndexerSingleton == nullptr) {
			_AssetIndexerSingleton = memnew(DynamicAssetIndexer);
			_AssetIndexerSingleton->index_files();
		}

		return _AssetIndexerSingleton;
	}

	static void destory_singleton() {
		if (_AssetIndexerSingleton != nullptr) {
			memdelete(_AssetIndexerSingleton);
			_AssetIndexerSingleton = nullptr;
		}
	}

	DynamicAssetIndexer();
	~DynamicAssetIndexer();
	
	void index_files();
	void re_index_files();
	String get_asset_path(Identifier* asset_id);

	void dump_asset_map();
	Variant get_asset_map();
};

} //namespace godot
