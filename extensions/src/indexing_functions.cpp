#include "identifier.hpp"

#include <gdextension_interface.h>

#include <godot_cpp/templates/hash_map.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/translation.hpp>
#include <godot_cpp/classes/translation_server.hpp>

using namespace godot;

static inline Ref<Translation> _load_translation_from_json(JSON* lang_data, String locale){
	Ref<Translation> translation;
	translation.instantiate();

	translation->set_locale(locale);

	if (lang_data == nullptr){
		return translation;
	}

	if (lang_data->get_data().get_type() != Variant::DICTIONARY){
		return translation;
	}

	Dictionary lang_data_dict = static_cast<Dictionary>(lang_data->get_data());

	auto keys = lang_data_dict.keys();
	for (int64_t i = 0; i < keys.size(); i++){
		String key = keys[i];
		String value = lang_data_dict[key];

		translation->add_message(key, value);
	}

	return translation;
}

static inline void _load_lang_files(String pack_name, String asset_group, HashMap<String, String>& asset_map){
	auto lang_dir = DirAccess::open("user://external/" + pack_name + "/" + asset_group + "/lang");
	if (lang_dir == nullptr){
		UtilityFunctions::print("Failed to open lang directory for " + asset_group + " in " + pack_name);
		return;
	}

	lang_dir->list_dir_begin();
	String lang_file = lang_dir->get_next();

	while (lang_file != ""){
		if (!lang_dir->current_is_dir() && lang_file.ends_with(".json")){
			String lang_path = "user://external/" + pack_name + "/" + asset_group + "/lang/" + lang_file;
			String locale = lang_file.substr(0, lang_file.length() - 5);

			Ref<Resource> raw_lang_data = ResourceLoader::get_singleton()->load(lang_path);
			if (raw_lang_data != nullptr && raw_lang_data.is_valid() && raw_lang_data->is_class("JSON")){
				auto lang_data = Object::cast_to<JSON>(raw_lang_data.ptr());
				if (lang_data != nullptr){
					auto new_translation = _load_translation_from_json(lang_data, locale);
					TranslationServer::get_singleton()->add_translation(new_translation);
				}
			}
		}

		lang_file = lang_dir->get_next();
	}
}


static inline void _index_textures(String pack_name, String asset_group, HashMap<String, String>& asset_map, String texture_subdir){
	auto texture_dir = DirAccess::open("user://external/" + pack_name + "/" + asset_group + "/" + texture_subdir);
	if (texture_dir == nullptr){
		UtilityFunctions::print("Failed to open texture directory");
		return;
	}
	
	UtilityFunctions::print("loading textures for " + pack_name + "/" + asset_group + "/" + texture_subdir);

	texture_dir->list_dir_begin();
	String texture_name = texture_dir->get_next();
	while (texture_name != ""){
		if (texture_dir->current_is_dir()){
			_index_textures(pack_name, asset_group, asset_map, texture_subdir + "/" + texture_name);
		}
		else{
			// load texture
			String texture_path = "user://external/" + pack_name + "/" + asset_group + "/" + texture_subdir + "/" + texture_name;
			String texture_basename = texture_name.get_basename();
			
			Identifier* texture_id = Identifier::from_values(asset_group, texture_subdir + "/" + texture_basename);

			asset_map[texture_id->to_string()] = texture_path;
			UtilityFunctions::print("Indexed texture: " + texture_id->to_string());
		}

		texture_name = texture_dir->get_next();
	}
}

static inline void _index_asset_group(String pack_name, String asset_group, HashMap<String, String>& asset_map){
	auto group_dir = DirAccess::open("user://external/" + pack_name + "/" + asset_group);
	if (group_dir == nullptr){
		UtilityFunctions::print("Failed to open group directory: " + asset_group);
		return;
	}

	group_dir->list_dir_begin();
	String asset_type = group_dir->get_next();

	while (asset_type != ""){
        UtilityFunctions::print("Indexing asset type: " + asset_type + " in " + pack_name + "/" + asset_group);
		if (group_dir->current_is_dir()){
			// use a different functions depending on the asset type
			if (asset_type == "lang"){
				_load_lang_files(pack_name, asset_group, asset_map);
			}

			if (asset_type == "textures"){
				_index_textures(pack_name, asset_group, asset_map, "textures");
			}
		}
			
		asset_type = group_dir->get_next();
	}
}

static inline void _index_asset_pack(String pack_name, HashMap<String, String>& asset_map){
	auto pack_dir = DirAccess::open("user://external/" + pack_name);
	if (pack_dir == nullptr){
		UtilityFunctions::print("Failed to open pack directory: " + pack_name);
		return;
	}

	pack_dir->list_dir_begin();
	String asset_group = pack_dir->get_next();

	while (asset_group != ""){
        UtilityFunctions::print("Indexing asset group: " + asset_group + " in " + pack_name);

		if (pack_dir->current_is_dir()){
			_index_asset_group(pack_name, asset_group, asset_map);
		}
			
		asset_group = pack_dir->get_next();
	}

}
