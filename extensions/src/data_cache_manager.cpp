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


//This is the binding code for the DataCacheManager class
//It is used to expose the class to the Godot engine
void DataCacheManager::_bind_methods() {
	//ClassDB::bind_static_method("Identifier", D_METHOD("from_string", "_id_string"), &Identifier::from_string);
    ClassDB::bind_static_method("DataCacheManager", D_METHOD("get_file_hash", "file_path"), &DataCacheManager::get_file_hash);
	ClassDB::bind_static_method("DataCacheManager", D_METHOD("get_string_hash", "str"), &DataCacheManager::get_string_hash);
	
	//ClassDB::bind_method(D_METHOD("get_group"), &Identifier::get_group);
	ClassDB::bind_method(D_METHOD("index_files"), &DataCacheManager::index_files);
	ClassDB::bind_method(D_METHOD("re_index_files"), &DataCacheManager::re_index_files);

	ClassDB::bind_method(D_METHOD("cache_file", "file_path"), &DataCacheManager::cache_file);
	ClassDB::bind_method(D_METHOD("cache_string", "str"), &DataCacheManager::cache_string);

	ClassDB::bind_method(D_METHOD("is_cached", "hash"), &DataCacheManager::is_cached);
	ClassDB::bind_method(D_METHOD("get_cached_string", "hash"), &DataCacheManager::get_cached_string);
	ClassDB::bind_method(D_METHOD("get_cached_json", "hash"), &DataCacheManager::get_cached_json);

	ClassDB::bind_method(D_METHOD("dump_hash_map"), &DataCacheManager::dump_hash_map);
	ClassDB::bind_method(D_METHOD("get_hash_map"), &DataCacheManager::get_hash_map);
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

	return FileAccess::get_sha256(file_path);
}


String DataCacheManager::get_string_hash(String str){
	//Start a SHA-256 context.
    HashingContext ctx{};
    ctx.start(HashingContext::HashType::HASH_SHA256);
	ctx.update(str.to_utf8_buffer());

	return ctx.finish().hex_encode();
}


String DataCacheManager::cache_file(String file_path){
	String raw_data = FileAccess::get_file_as_string(file_path);
	if (raw_data == ""){
		UtilityFunctions::print("Failed to read file: " + file_path);
		return "";
	}
	return cache_string(raw_data);
}


String DataCacheManager::cache_string(String str){
	if (!files_indexed){
		index_files();
	}

	// hash the string, if it is already cached or cannot be hashed, return the result of the hash function
	String hash = get_string_hash(str);
	if (hash == ""){
		return "";
	}

	if (is_cached(hash)){
		return hash;
	}

	JSON* json = memnew(JSON);
	Error error = json->parse(str);
	if (error != OK){
		UtilityFunctions::print("JSON Parse Error: ", json->get_error_message(), " in ", str, " at line ", json->get_error_line());
		return "";
	}
	memdelete(json);

	// write the data to a file
	String cache_dir_str = "user://cache";
	DirAccess::make_dir_absolute(cache_dir_str);

	String cache_file_path = cache_dir_str + "/" + hash + ".json";
	auto cache_file = FileAccess::open(cache_file_path, FileAccess::WRITE);
	if (cache_file == nullptr){
		UtilityFunctions::print("Failed to open cache file for writing: " + cache_file_path);
		return "";
	}

	cache_file->store_string(str);
	cache_file->close();

	hashed_data_map[hash] = cache_file_path;
	return hash;
}


bool DataCacheManager::is_cached(String hash){
	if (!files_indexed){
		index_files();
	}

	return hashed_data_map.find(hash) != hashed_data_map.end();
}


String DataCacheManager::get_cached_string(String hash){
	if (!files_indexed){
		index_files();
	}

	if (!is_cached(hash)){
		return "";
	}

	return FileAccess::get_file_as_string(hashed_data_map[hash]);
}


Ref<JSON> DataCacheManager::get_cached_json(String hash){
	String cached_string = get_cached_string(hash);
	if (cached_string == ""){
		return nullptr;
	}

	Ref<JSON> json = memnew(JSON);
	Error error = json->parse(cached_string);
	if (error != OK){
		UtilityFunctions::print("JSON Parse Error: ", json->get_error_message(), " in ", cached_string, " at line ", json->get_error_line());
		return nullptr;
	}

	return json;
}


void DataCacheManager::dump_hash_map() {
	if (!files_indexed){
		index_files();
	}

	UtilityFunctions::print("Asset map with size ", hashed_data_map.size());
    for ( const auto& [key, value] : hashed_data_map ) {
        UtilityFunctions::print(key, " : ", value.ascii().get_data());
    }
}


Variant DataCacheManager::get_hash_map() {
	if (!files_indexed){
		index_files();
	}

	Dictionary map;
	for ( const auto& [key, value] : hashed_data_map ) {
		map[key] = value;
	}
	return map;
}
