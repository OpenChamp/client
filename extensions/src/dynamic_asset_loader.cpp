#include "dynamic_asset_loader.hpp"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void DynamicAssetLoader::_bind_methods() {
	//ClassDB::bind_static_method("Identifier", D_METHOD("from_string", "_id_string"), &Identifier::from_string);
	//ClassDB::bind_static_method("Identifier", D_METHOD("from_values", "_group", "_name"), &Identifier::from_values);
	
	//ClassDB::bind_method(D_METHOD("get_group"), &Identifier::get_group);
	ClassDB::bind_method(D_METHOD("dump_asset_map"), &DynamicAssetLoader::dump_asset_map);
}

DynamicAssetLoader::DynamicAssetLoader() {}

DynamicAssetLoader::~DynamicAssetLoader() {}

void DynamicAssetLoader::dump_asset_map() {
    for ( const auto& [key, value] : asset_map ) {
        
        printf("%s: %s", key.ascii().get_data(), value.ascii().get_data());
    }
}
