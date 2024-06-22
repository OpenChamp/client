#pragma once

#include "base_include.hpp"
#include "godot_cpp/classes/mutex.hpp"
#include "godot_cpp/core/mutex_lock.hpp"

#include "identifier.hpp"

namespace godot {

class GDE_EXPORT DynamicAssetIndexer : public Object {
	GDCLASS(DynamicAssetIndexer, Object)

private:
    HashMap<String, String> asset_map;
	bool files_indexed = false;
	
	Ref<godot::Mutex> index_mutex = nullptr;

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
