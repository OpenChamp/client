#include "identifier.hpp"
#include "data_cache_manager.hpp"

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


static inline void _load_lang_files(String pack_path, String asset_group, HashMap<String, String>& asset_map){
	auto lang_dir = DirAccess::open(pack_path + "/" + asset_group + "/lang");
	if (lang_dir == nullptr){
		UtilityFunctions::print("Failed to open lang directory for " + asset_group + " in " + pack_path);
		return;
	}

	lang_dir->list_dir_begin();
	String lang_file = "";

	while ((lang_file = lang_dir->get_next()) != ""){
		if (lang_dir->current_is_dir()){
			continue;
		}

		if (!lang_file.ends_with(".json")){
			continue;
		}

		String lang_path = pack_path + "/" + asset_group + "/lang/" + lang_file;
		String locale = lang_file.substr(0, lang_file.length() - 5);

		Ref<Resource> raw_lang_data = ResourceLoader::get_singleton()->load(lang_path);
		if (raw_lang_data == nullptr || !raw_lang_data.is_valid()){
			UtilityFunctions::print("Failed to load lang file: " + lang_path);
			continue;
		}

		if (!raw_lang_data->is_class("JSON")){
			UtilityFunctions::print("Lang file is not a JSON file: " + lang_path);
			continue;
		}

		auto lang_data = Object::cast_to<JSON>(raw_lang_data.ptr());
		if (lang_data == nullptr){
			UtilityFunctions::print("Failed to cast lang data to JSON: " + lang_path);
			continue;
		}

		auto new_translation = _load_translation_from_json(lang_data, locale);
		TranslationServer::get_singleton()->add_translation(new_translation);
	}
}


static inline void _index_textures(String pack_path, String asset_group, HashMap<String, String>& asset_map, String texture_subdir){
	auto texture_dir = DirAccess::open(pack_path + "/" + asset_group + "/" + texture_subdir);
	if (texture_dir == nullptr){
		UtilityFunctions::print("Failed to open texture directory");
		return;
	}
	
	UtilityFunctions::print("loading textures for " + pack_path + "/" + asset_group + "/" + texture_subdir);

	texture_dir->list_dir_begin();
	String texture_name = "";
	while ((texture_name = texture_dir->get_next()) != ""){
		if (texture_dir->current_is_dir()){
			_index_textures(pack_path, asset_group, asset_map, texture_subdir + "/" + texture_name);
		}else{
			if (texture_name.ends_with(".import")){
				continue;
			}

			// load texture
			String texture_path = pack_path + "/" + asset_group + "/" + texture_subdir + "/" + texture_name;
			String texture_basename = texture_name.get_basename();
			
			Identifier* texture_id = Identifier::from_values(asset_group, texture_subdir + "/" + texture_basename);

			asset_map[texture_id->to_string()] = texture_path;
			UtilityFunctions::print("Indexed texture: " + texture_id->to_string());
		}
	}
}


static inline void _index_fonts(String pack_path, String asset_group, HashMap<String, String>& asset_map){
	auto font_dir = DirAccess::open(pack_path + "/" + asset_group + "/fonts");
	if (font_dir == nullptr){
		UtilityFunctions::print("Failed to open font directory");
		return;
	}
	
	UtilityFunctions::print("loading fonts for " + pack_path + "/" + asset_group);

	font_dir->list_dir_begin();
	String font_name = "";
	while ((font_name = font_dir->get_next()) != ""){
		if (font_dir->current_is_dir()){
			continue;
		}

		if (font_name.ends_with(".import")){
			continue;
		}

		// load font
		String font_path = pack_path + "/" + asset_group + "/fonts/" + font_name;
		String font_basename = font_name.get_basename();
		
		Identifier* font_id = Identifier::from_values(asset_group, "fonts/" + font_basename);

		asset_map[font_id->to_string()] = font_path;
		UtilityFunctions::print("Indexed font: " + font_id->to_string());
		
	}
}


static inline void _cache_patch_data(String pack_path, String asset_group, HashMap<String, String>& asset_map){
	auto patches_dir = DirAccess::open(pack_path + "/" + asset_group + "/patchdata");
	if (patches_dir == nullptr){
		UtilityFunctions::print("Failed to open patchdata directory");
		return;
	}

	patches_dir->list_dir_begin();
	String gamemode_name = "";

	while ((gamemode_name = patches_dir->get_next()) != ""){
		if (!patches_dir->current_is_dir()){
			continue;
		}

		UtilityFunctions::print("Caching patch data for gamemode: " + gamemode_name);

		Vector<String> patch_types = {"characters", "items"};

		for (String patch_type:patch_types){

			auto gamemode_dir = DirAccess::open(pack_path + "/" + asset_group + "/patchdata/" + gamemode_name + "/" + patch_type);
			if (gamemode_dir == nullptr){
				UtilityFunctions::print("Failed to open gamemode directory: " + gamemode_name);
				continue;
			}

			gamemode_dir->list_dir_begin();
			String patch_file = "";
			while ((patch_file = gamemode_dir->get_next()) != ""){
				if (gamemode_dir->current_is_dir()){
					continue;
				}

				if (!patch_file.ends_with(".json")){
					continue;
				}

				String patch_path = pack_path + "/" + asset_group + "/patchdata/" + gamemode_name + "/" + patch_type + "/" + patch_file;
				String file_hash = DataCacheManager::get_singleton()->cache_file(patch_path);
				
				UtilityFunctions::print("Cached file '" + patch_path + "' with hash: " + file_hash);
			}
		}
		
	}
}


static inline void _index_asset_group(String pack_path, String asset_group, HashMap<String, String>& asset_map){
	auto group_dir = DirAccess::open(pack_path + "/" + asset_group);
	if (group_dir == nullptr){
		UtilityFunctions::print("Failed to open group directory: " + asset_group);
		return;
	}

	group_dir->list_dir_begin();
	String asset_type = group_dir->get_next();

	while (asset_type != ""){
        UtilityFunctions::print("Indexing asset type: " + asset_type + " in " + pack_path + "/" + asset_group);
		if (group_dir->current_is_dir()){
			// use a different functions depending on the asset type
			if (asset_type == "lang"){
				_load_lang_files(pack_path, asset_group, asset_map);
			}

			if (asset_type == "textures"){
				_index_textures(pack_path, asset_group, asset_map, "textures");
			}

			if (asset_type == "fonts"){
				_index_fonts(pack_path, asset_group, asset_map);
			}

			if (asset_type == "patchdata"){
				_cache_patch_data(pack_path, asset_group, asset_map);
			}
		}
			
		asset_type = group_dir->get_next();
	}
}


static inline void _index_asset_pack(String pack_path, HashMap<String, String>& asset_map){
	auto pack_dir = DirAccess::open(pack_path);
	if (pack_dir == nullptr){
		UtilityFunctions::print("Failed to open pack directory: " + pack_path);
		return;
	}

	pack_dir->list_dir_begin();
	String asset_group = pack_dir->get_next();

	while (asset_group != ""){
        UtilityFunctions::print("Indexing asset group: " + asset_group + " in " + pack_path);

		if (pack_dir->current_is_dir()){
			_index_asset_group(pack_path, asset_group, asset_map);
		}
			
		asset_group = pack_dir->get_next();
	}

}
