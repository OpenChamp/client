#include "path_mesh_3d.hpp"
#include "path_extrude_3d.hpp"
#include "path_multimesh_3d.hpp"
#include "path_scene_3d.hpp"
#include "path_modifier_3d.hpp"
#include "path_extrude_profile_base.hpp"
#include "extrude_profiles/path_extrude_profile_manual.hpp"
#include "extrude_profiles/path_extrude_profile_rect.hpp"
#include "extrude_profiles/path_extrude_profile_circle.hpp"
#include "path_static_body_3d.hpp"
#include "path_area_3d.hpp"
#include "register_types.hpp"

void initialize_path_mesh_3d(ModuleInitializationLevel p_level) {
	if (p_level == MODULE_INITIALIZATION_LEVEL_SCENE) {
        GDREGISTER_CLASS(PathMesh3D)
        GDREGISTER_CLASS(PathExtrude3D)
        GDREGISTER_CLASS(PathMultiMesh3D)
        GDREGISTER_CLASS(PathScene3D)
        GDREGISTER_CLASS(PathModifier3D)
        GDREGISTER_CLASS(PathExtrudeProfileBase)
        GDREGISTER_CLASS(PathExtrudeProfileManual)
        GDREGISTER_CLASS(PathExtrudeProfileRect)
        GDREGISTER_CLASS(PathExtrudeProfileCircle)
        GDREGISTER_CLASS(PathStaticBody3D)
        GDREGISTER_CLASS(PathArea3D)
    }
}

void uninitialize_path_mesh_3d(ModuleInitializationLevel p_level) {
	
}

extern "C" {
    // Initialization.
    GDExtensionBool GDE_EXPORT path_mesh_3d_init(
            GDExtensionInterfaceGetProcAddress p_get_proc_address, 
            const GDExtensionClassLibraryPtr p_library, 
            GDExtensionInitialization *r_initialization) {
        godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

        init_obj.register_initializer(initialize_path_mesh_3d);
        init_obj.register_terminator(uninitialize_path_mesh_3d);
        init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

        return init_obj.init();
    }

}