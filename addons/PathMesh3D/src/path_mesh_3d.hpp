#pragma once

#include <godot_cpp/classes/geometry_instance3d.hpp>
#include <godot_cpp/templates/pair.hpp>
#include <godot_cpp/classes/array_mesh.hpp>

#include "path_tool.hpp"
#include "path_collision_tool.hpp"

namespace godot {
class PathMesh3D : public GeometryInstance3D {
    GDCLASS(PathMesh3D, GeometryInstance3D)
    PATH_TOOL(PathMesh3D, MESH)
    PATH_MESH_WITH_COLLISION(generated_mesh)

public:
    enum Distribution {
        DISTRIBUTE_BY_MODEL_LENGTH,
        DISTRIBUTE_BY_COUNT,
        DISTRIBUTE_MAX
    };
    enum Alignment {
        ALIGN_STRETCH,
        ALIGN_FROM_START,
        ALIGN_CENTERED,
        ALIGN_FROM_END,
        ALIGN_MAX
    };

    void set_mesh(const Ref<Mesh> &p_mesh);
    Ref<Mesh> get_mesh() const;

    void set_tile_rotation(uint64_t p_surface_idx, Vector3 p_rotation);
    Vector3 get_tile_rotation(uint64_t p_surface_idx) const;

    void set_tile_rotation_order(uint64_t p_surface_idx, EulerOrder p_order);
    EulerOrder get_tile_rotation_order(uint64_t p_surface_idx) const;

    void set_distribution(uint64_t p_surface_idx, Distribution p_distribution);
    Distribution get_distribution(uint64_t p_surface_idx) const;

    void set_alignment(uint64_t p_surface_idx, Alignment p_alignment);
    Alignment get_alignment(uint64_t p_surface_idx) const;

    void set_count(uint64_t p_surface_idx, uint64_t p_count);
    uint64_t get_count(uint64_t p_surface_idx) const;

    void set_warp_along_curve(uint64_t p_surface_idx, bool p_warp);
    bool get_warp_along_curve(uint64_t p_surface_idx) const;

    void set_sample_cubic(uint64_t p_surface_idx, bool p_cubic);
    bool get_sample_cubic(uint64_t p_surface_idx) const;

    void set_tilt(uint64_t p_surface_idx, bool p_tilt);
    bool get_tilt(uint64_t p_surface_idx) const;

    void set_offset(uint64_t p_surface_idx, Vector2 p_offset);
    Vector2 get_offset(uint64_t p_surface_idx) const;
    
    Ref<ArrayMesh> get_baked_mesh() const;

    uint64_t get_triangle_count(uint64_t p_surface_idx) const;
    uint64_t get_total_triangle_count() const;

    PathMesh3D();
    ~PathMesh3D() override;

protected:
    static void _bind_methods();
	void _get_property_list(List<PropertyInfo> *p_list) const;
	bool _property_can_revert(const StringName &p_name) const;
	bool _property_get_revert(const StringName &p_name, Variant &r_property) const;
    bool _set(const StringName &p_name, const Variant &p_property);
	bool _get(const StringName &p_name, Variant &r_property) const;

private:
    Ref<Mesh> source_mesh;
    Ref<ArrayMesh> generated_mesh;
    struct SurfaceData {
        Vector3 tile_rotation = Vector3();
        EulerOrder tile_rotation_order = EulerOrder::EULER_ORDER_YXZ;
        Distribution distribution = Distribution::DISTRIBUTE_BY_MODEL_LENGTH;
        Alignment alignment = Alignment::ALIGN_STRETCH;
        uint64_t count = 2;
        bool warp_along_curve = true;
        bool cubic = false;
        bool tilt = true;
        Vector2 offset = Vector2();
        uint64_t n_tris = 0;
    };
    LocalVector<SurfaceData> surfaces;

    Pair<uint64_t, String> _decode_dynamic_propname(const StringName &p_name) const;
    double _get_mesh_length() const;
    uint64_t _get_max_count() const;
    void _on_mesh_changed();
};

}

VARIANT_ENUM_CAST(PathMesh3D::RelativeTransform)
VARIANT_ENUM_CAST(PathMesh3D::Distribution)
VARIANT_ENUM_CAST(PathMesh3D::Alignment)
VARIANT_ENUM_CAST(PathMesh3D::CollisionMode)