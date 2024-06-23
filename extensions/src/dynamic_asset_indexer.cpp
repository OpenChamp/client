#include "dynamic_asset_indexer.hpp"

#include "indexing_functions.cpp"

#include <godot_cpp/core/class_db.hpp>

//This is the binding code for the DynamicAssetIndexer class
//It is used to expose the class to the Godot engine
void DynamicAssetIndexer::_bind_methods() {
	//ClassDB::bind_static_method("Identifier", D_METHOD("from_string", "_id_string"), &Identifier::from_string);
	//ClassDB::bind_static_method("Identifier", D_METHOD("from_values", "_group", "_name"), &Identifier::from_values);
	
	//ClassDB::bind_method(D_METHOD("get_group"), &Identifier::get_group);
	ClassDB::bind_method(D_METHOD("index_files"), &DynamicAssetIndexer::index_files);
	ClassDB::bind_method(D_METHOD("re_index_files"), &DynamicAssetIndexer::re_index_files);
	ClassDB::bind_method(D_METHOD("get_asset_path"), &DynamicAssetIndexer::get_asset_path);
	ClassDB::bind_method(D_METHOD("dump_asset_map"), &DynamicAssetIndexer::dump_asset_map);
	ClassDB::bind_method(D_METHOD("get_asset_map"), &DynamicAssetIndexer::get_asset_map);
}

DynamicAssetIndexer* DynamicAssetIndexer::_AssetIndexerSingleton = nullptr;

DynamicAssetIndexer::DynamicAssetIndexer():index_mutex{memnew(godot::Mutex)} {}

DynamicAssetIndexer::~DynamicAssetIndexer() {}

void DynamicAssetIndexer::index_files(){
	if (files_indexed){
		return;
	}

	MutexLock lock{**index_mutex};
	files_indexed = true;

	// Index res://default_assets as the base pack first
	UtilityFunctions::print("Indexing asset pack res://default_assets");
	_index_asset_pack("res://default_assets", asset_map);

	// Now the external packs get loaded
	// These will always overwrite the resources in the default pack
	auto packs_dir = DirAccess::open("user://external"); 
	if (packs_dir == nullptr){
		UtilityFunctions::print("Failed to open external directory");
		return;
	}

	packs_dir->list_dir_begin();
	String asset_pack = packs_dir->get_next();

	UtilityFunctions::print("Indexing asset packs from user://external");

	while (asset_pack != ""){
		UtilityFunctions::print("Indexing asset pack: " + asset_pack);

		String pack_path = "user://external/" + asset_pack;
		if (packs_dir->current_is_dir()){
			_index_asset_pack(pack_path, asset_map);
		}
			
		asset_pack = packs_dir->get_next();
	}
}

void DynamicAssetIndexer::re_index_files(){
	{
		MutexLock lock{**index_mutex};
		asset_map.clear();
		files_indexed = false;
	}
	
	index_files();
}

String DynamicAssetIndexer::get_asset_path(Identifier* asset_id){
	index_files();

	String asset_id_string = asset_id->to_string();	

	if (!asset_map.has(asset_id_string)){
		UtilityFunctions::print("Asset not found in index: " + asset_id->to_string());
		return "";
	}
	
	return asset_map[asset_id_string];
}

void DynamicAssetIndexer::dump_asset_map() {
	index_files();

	UtilityFunctions::print("Asset map with size ", asset_map.size());
    for ( const auto& [key, value] : asset_map ) {
        UtilityFunctions::print(key, " : ", value.ascii().get_data());
    }
}

Variant DynamicAssetIndexer::get_asset_map() {
	index_files();

	Dictionary map;
	for ( const auto& [key, value] : asset_map ) {
		map[key] = value;
	}
	return map;
}