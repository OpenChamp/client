#pragma once

#include "identifier.hpp"

#include "godot_cpp/classes/object.hpp"
#include "godot_cpp/templates/hash_map.hpp"
#include <godot_cpp/classes/json.hpp>

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

	String cache_file(String file_path);
	String cache_string(String str);

	bool is_cached(String hash);
	String get_cached_string(String hash);
	Ref<JSON> get_cached_json(String hash);

	void dump_hash_map();
	Variant get_hash_map();

    static String get_file_hash(String file_path);
	static String get_string_hash(String str);
};

} //namespace godot
