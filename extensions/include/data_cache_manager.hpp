#pragma once

#include "godot_cpp/classes/object.hpp"
#include "godot_cpp/templates/hash_map.hpp"
#include "identifier.hpp"

namespace godot {

class DataCacheManager : public Object {
	GDCLASS(DataCacheManager, Object)

private:
    HashMap<String, String> hashed_data_map;
	bool files_indexed = false;

	static DataCacheManager* _DataCacheManagerSingleton;

protected:
	static void _bind_methods();

public:
	static DataCacheManager* get_singleton() { 
		if (_DataCacheManagerSingleton == nullptr) {
			_DataCacheManagerSingleton = memnew(DataCacheManager);
			_DataCacheManagerSingleton->index_files();
		}

		return _DataCacheManagerSingleton;
	}

	static void destory_singleton() {
		if (_DataCacheManagerSingleton != nullptr) {
			memdelete(_DataCacheManagerSingleton);
			_DataCacheManagerSingleton = nullptr;
		}
	}

	DataCacheManager();
	~DataCacheManager();
	
	void index_files();
	void re_index_files();

	void dump_asset_map();
	Variant get_asset_map();

    static String get_file_hash(String file_path);
};

} //namespace godot
