#pragma once

#include <godot_cpp/classes/geometry_instance3d.hpp>
#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/material.hpp>

#include "path_tool.hpp"
#include "path_collision_tool.hpp"
#include "path_extrude_profile_base.hpp"

namespace godot {

class PathExtrude3D : public GeometryInstance3D {
    GDCLASS(PathExtrude3D, GeometryInstance3D)
    PATH_TOOL(PathExtrude3D, MESH)
    PATH_MESH_WITH_COLLISION(generated_mesh)

public:
    enum EndCaps {
        END_CAPS_NONE = 0, 
        END_CAPS_START = 1 << 0, 
        END_CAPS_END = 1 << 1, 
        END_CAPS_BOTH = END_CAPS_START | END_CAPS_END
    };
    void set_profile(const Ref<PathExtrudeProfileBase> &p_profile);
    Ref<PathExtrudeProfileBase> get_profile() const;

    void set_tessellation_max_stages(const int32_t p_tessellation_max_stages);
    int32_t get_tessellation_max_stages() const;

    void set_tessellation_tolerance_degrees(const double p_tessellation_tolerance_degrees);
    double get_tessellation_tolerance_degrees() const;

    void set_end_cap_mode(const BitField<EndCaps> p_end_cap_mode);
    BitField<EndCaps> get_end_cap_mode() const;

    void set_offset(const Vector2 p_offset);
    Vector2 get_offset() const;

    void set_offset_angle(const double p_offset_angle);
    double get_offset_angle() const;

    void set_sample_cubic(const bool p_cubic);
    bool get_sample_cubic() const;

    void set_tilt(const bool p_tilt);
    bool get_tilt() const;

    void set_material(const Ref<Material> &p_material);
    Ref<Material> get_material() const;

    Ref<ArrayMesh> get_baked_mesh() const;

    uint64_t get_triangle_count() const;

    PathExtrude3D();
    ~PathExtrude3D();

protected:
    static void _bind_methods();

private:
    Ref<PathExtrudeProfileBase> profile;
    Ref<ArrayMesh> generated_mesh;

    int32_t tessellation_max_stages = 5;
    double tessellation_tolerance_degrees = 4.0;
    Vector2 offset = Vector2();
    double offset_angle = 0.0;
    bool sample_cubic = false;
    bool tilt = true;
    EndCaps end_cap_mode = END_CAPS_BOTH;
    Ref<Material> material;
    uint64_t n_tris = 0;

    void _on_profile_changed();
};
}

VARIANT_ENUM_CAST(PathExtrude3D::RelativeTransform)
VARIANT_BITFIELD_CAST(PathExtrude3D::EndCaps)
VARIANT_ENUM_CAST(PathExtrude3D::CollisionMode)