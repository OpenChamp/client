#include "data_cache_manager.hpp"

#include <gdextension_interface.h>

#include <godot_cpp/templates/hash_map.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/hashing_context.hpp>
#include <godot_cpp/classes/translation.hpp>
#include <godot_cpp/classes/translation_server.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

const constexpr int HASH_CHUNK_SIZE = 1024;

//This is the binding code for the DataCacheManager class
//It is used to expose the class to the Godot engine
void DataCacheManager::_bind_methods() {
	//ClassDB::bind_static_method("Identifier", D_METHOD("from_string", "_id_string"), &Identifier::from_string);
    ClassDB::bind_static_method("DataCacheManager", D_METHOD("get_file_hash", "file_path"), &DataCacheManager::get_file_hash);
	
	//ClassDB::bind_method(D_METHOD("get_group"), &Identifier::get_group);
	ClassDB::bind_method(D_METHOD("index_files"), &DataCacheManager::index_files);
	ClassDB::bind_method(D_METHOD("re_index_files"), &DataCacheManager::re_index_files);
	ClassDB::bind_method(D_METHOD("dump_asset_map"), &DataCacheManager::dump_asset_map);
	ClassDB::bind_method(D_METHOD("get_asset_map"), &DataCacheManager::get_asset_map);
}

DataCacheManager* DataCacheManager::_DataCacheManagerSingleton = nullptr;

DataCacheManager::DataCacheManager() {}

DataCacheManager::~DataCacheManager() {}

void DataCacheManager::index_files(){
	files_indexed = true;

    String cache_dir_str = "user://cache";
    DirAccess::make_dir_absolute(cache_dir_str);

    auto cache_dir = DirAccess::open(cache_dir_str);
	if (cache_dir == nullptr){
		UtilityFunctions::print("Failed to open pack directory: " + cache_dir_str);
		return;
	}

	cache_dir->list_dir_begin();
	String cached_file = "";

	while ((cached_file = cache_dir->get_next()) != ""){
        UtilityFunctions::print("Found the following hash in cache:" + cached_file);

		if (cache_dir->current_is_dir()){
            continue;
        }

        if (!cached_file.ends_with(".json")){
            continue;
        }

        String expected_hash = cached_file.substr(0, cached_file.length() - 5);
        String actual_hash = get_file_hash(cache_dir_str + "/" + cached_file);

        if (expected_hash == actual_hash){
            hashed_data_map[expected_hash] = cache_dir_str + "/" + cached_file;
        }
	}
}

void DataCacheManager::re_index_files(){
	hashed_data_map.clear();
	files_indexed = false;
	index_files();
}

String DataCacheManager::get_file_hash(String file_path){
    if (!FileAccess::file_exists(file_path)){
        return "";
    }
	
	//Start a SHA-256 context.
    HashingContext ctx{};
    ctx.start(HashingContext::HashType::HASH_SHA256);
	
	auto file = FileAccess::open(file_path, FileAccess::ModeFlags::READ);
	while (!file->eof_reached()){
		ctx.update(file->get_buffer(HASH_CHUNK_SIZE));
    }

	return ctx.finish().hex_encode();
}

void DataCacheManager::dump_asset_map() {
	if (!files_indexed){
		index_files();
	}

	UtilityFunctions::print("Asset map with size ", hashed_data_map.size());
    for ( const auto& [key, value] : hashed_data_map ) {
        UtilityFunctions::print(key, " : ", value.ascii().get_data());
    }
}

Variant DataCacheManager::get_asset_map() {
	if (!files_indexed){
		index_files();
	}

	Dictionary map;
	for ( const auto& [key, value] : hashed_data_map ) {
		map[key] = value;
	}
	return map;
}