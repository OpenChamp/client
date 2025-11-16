#include <godot_cpp/classes/curve3d.hpp>
#include <godot_cpp/classes/material.hpp>

#include "path_mesh_3d.hpp"


using namespace godot;

#define CHECK_SURFACE_IDX(m_idx) ERR_FAIL_COND(m_idx < 0 || m_idx >= surfaces.size())
#define CHECK_SURFACE_IDX_V(m_idx, m_ret) ERR_FAIL_COND_V(m_idx < 0 || m_idx >= surfaces.size(), m_ret)

void PathMesh3D::set_tile_rotation(uint64_t p_surface_idx, Vector3 p_rotation) {
    CHECK_SURFACE_IDX(p_surface_idx);

    if (surfaces[p_surface_idx].tile_rotation != p_rotation) {
        surfaces[p_surface_idx].tile_rotation = p_rotation;
        queue_rebuild();
    }
}

Vector3 PathMesh3D::get_tile_rotation(uint64_t p_surface_idx) const {
    CHECK_SURFACE_IDX_V(p_surface_idx, Vector3());

    return surfaces[p_surface_idx].tile_rotation;
}

void PathMesh3D::set_tile_rotation_order(uint64_t p_surface_idx, EulerOrder p_order) {
    CHECK_SURFACE_IDX(p_surface_idx);

    if (surfaces[p_surface_idx].tile_rotation_order != p_order) {
        surfaces[p_surface_idx].tile_rotation_order = p_order;
        queue_rebuild();
    }
}

EulerOrder PathMesh3D::get_tile_rotation_order(uint64_t p_surface_idx) const {
    CHECK_SURFACE_IDX_V(p_surface_idx, EulerOrder::EULER_ORDER_YXZ);

    return surfaces[p_surface_idx].tile_rotation_order;
}

void PathMesh3D::set_distribution(uint64_t p_surface_idx, Distribution p_distribution) {
    CHECK_SURFACE_IDX(p_surface_idx);

    if (surfaces[p_surface_idx].distribution != p_distribution) {
        surfaces[p_surface_idx].distribution = p_distribution;
        queue_rebuild();
        notify_property_list_changed();
    }
}

auto PathMesh3D::get_distribution(uint64_t p_surface_idx) const -> Distribution {
    CHECK_SURFACE_IDX_V(p_surface_idx, Distribution::DISTRIBUTE_MAX);

    return surfaces[p_surface_idx].distribution;
}

void PathMesh3D::set_alignment(uint64_t p_surface_idx, Alignment p_alignment) {
    CHECK_SURFACE_IDX(p_surface_idx);
    
    if (surfaces[p_surface_idx].alignment != p_alignment) {
        surfaces[p_surface_idx].alignment = p_alignment;
        queue_rebuild();
    }
}

auto PathMesh3D::get_alignment(uint64_t p_surface_idx) const -> Alignment {
    CHECK_SURFACE_IDX_V(p_surface_idx, Alignment::ALIGN_MAX);

    return surfaces[p_surface_idx].alignment;
}

void PathMesh3D::set_count(uint64_t p_surface_idx, uint64_t p_count) {
    CHECK_SURFACE_IDX(p_surface_idx);
    p_count = Math::clamp(p_count, uint64_t(2), _get_max_count());

    if (surfaces[p_surface_idx].count != p_count) {
        surfaces[p_surface_idx].count = p_count;
        if (surfaces[p_surface_idx].distribution == DISTRIBUTE_BY_COUNT) {
            queue_rebuild();
        }
    }
}

uint64_t PathMesh3D::get_count(uint64_t p_surface_idx) const {
    CHECK_SURFACE_IDX_V(p_surface_idx, 0);

    return surfaces[p_surface_idx].distribution == Distribution::DISTRIBUTE_BY_COUNT ?
        surfaces[p_surface_idx].count : 0;
}

void PathMesh3D::set_warp_along_curve(uint64_t p_surface_idx, bool p_warp) {
    CHECK_SURFACE_IDX(p_surface_idx);

    if (surfaces[p_surface_idx].warp_along_curve != p_warp) {
        surfaces[p_surface_idx].warp_along_curve = p_warp;
        queue_rebuild();
    }
}

bool PathMesh3D::get_warp_along_curve(uint64_t p_surface_idx) const {
    CHECK_SURFACE_IDX_V(p_surface_idx, false);
    
    return surfaces[p_surface_idx].warp_along_curve;
}

void PathMesh3D::set_sample_cubic(uint64_t p_surface_idx, bool p_cubic) {
    CHECK_SURFACE_IDX(p_surface_idx);

    if (surfaces[p_surface_idx].cubic != p_cubic) {
        surfaces[p_surface_idx].cubic = p_cubic;
        queue_rebuild();
    }
}

bool PathMesh3D::get_sample_cubic(uint64_t p_surface_idx) const {
    CHECK_SURFACE_IDX_V(p_surface_idx, false);

    return surfaces[p_surface_idx].cubic;
}

void PathMesh3D::set_tilt(uint64_t p_surface_idx, bool p_tilt) {
    CHECK_SURFACE_IDX(p_surface_idx);

    if (surfaces[p_surface_idx].tilt != p_tilt) {
        surfaces[p_surface_idx].tilt = p_tilt;
        queue_rebuild();
    }
}

bool PathMesh3D::get_tilt(uint64_t p_surface_idx) const {
    CHECK_SURFACE_IDX_V(p_surface_idx, false);

    return surfaces[p_surface_idx].tilt;
}

void PathMesh3D::set_offset(uint64_t p_surface_idx, Vector2 p_offset) {
    CHECK_SURFACE_IDX(p_surface_idx);

    if (surfaces[p_surface_idx].offset != p_offset) {
        surfaces[p_surface_idx].offset = p_offset;
        queue_rebuild();
    }
}

Vector2 PathMesh3D::get_offset(uint64_t p_surface_idx) const {
    CHECK_SURFACE_IDX_V(p_surface_idx, Vector2());

    return surfaces[p_surface_idx].offset;
}

void PathMesh3D::set_mesh(const Ref<Mesh> &p_mesh) {
    if (p_mesh != source_mesh) {
        if (source_mesh.is_valid() && source_mesh->is_connected("changed", callable_mp(this, &PathMesh3D::_on_mesh_changed))) {
            source_mesh->disconnect("changed", callable_mp(this, &PathMesh3D::_on_mesh_changed));
        }

        source_mesh = p_mesh;

        if (source_mesh.is_valid()) {
            source_mesh->connect("changed", callable_mp(this, &PathMesh3D::_on_mesh_changed));
        }

        _on_mesh_changed();

        notify_property_list_changed();
    }
}

Ref<Mesh> PathMesh3D::get_mesh() const {
    return source_mesh;
}

Ref<ArrayMesh> PathMesh3D::get_baked_mesh() const {
    return generated_mesh->duplicate();
}

uint64_t PathMesh3D::get_triangle_count(uint64_t p_surface_idx) const {
    CHECK_SURFACE_IDX_V(p_surface_idx, 0);

    return surfaces[p_surface_idx].n_tris;
}

uint64_t PathMesh3D::get_total_triangle_count() const {
    uint64_t r_value = 0;
    for (const SurfaceData &surf : surfaces) {
        r_value += surf.n_tris;
    }

    return r_value;
}

void PathMesh3D::_bind_methods() {
    PATH_TOOL_BINDS(PathMesh3D, mesh, MESH)

    ClassDB::bind_method(D_METHOD("get_baked_mesh"), &PathMesh3D::get_baked_mesh);

    ClassDB::bind_method(D_METHOD("set_tile_rotation", "surface_index", "rotation"), &PathMesh3D::set_tile_rotation);
    ClassDB::bind_method(D_METHOD("get_tile_rotation", "surface_index"), &PathMesh3D::get_tile_rotation);
    ClassDB::bind_method(D_METHOD("set_tile_rotation_order", "surface_index", "order"), &PathMesh3D::set_tile_rotation_order);
    ClassDB::bind_method(D_METHOD("get_tile_rotation_order", "surface_index"), &PathMesh3D::get_tile_rotation_order);
    ClassDB::bind_method(D_METHOD("set_distribution", "surface_index", "distribution"), &PathMesh3D::set_distribution);
    ClassDB::bind_method(D_METHOD("get_distribution", "surface_index"), &PathMesh3D::get_distribution);
    ClassDB::bind_method(D_METHOD("set_alignment", "surface_index", "alignment"), &PathMesh3D::set_alignment);
    ClassDB::bind_method(D_METHOD("get_alignment", "surface_index"), &PathMesh3D::get_alignment);
    ClassDB::bind_method(D_METHOD("set_count", "surface_index", "count"), &PathMesh3D::set_count);
    ClassDB::bind_method(D_METHOD("get_count", "surface_index"), &PathMesh3D::get_count);
    ClassDB::bind_method(D_METHOD("set_warp_along_curve", "surface_index", "warp"), &PathMesh3D::set_warp_along_curve);
    ClassDB::bind_method(D_METHOD("get_warp_along_curve", "surface_index"), &PathMesh3D::get_warp_along_curve);
    ClassDB::bind_method(D_METHOD("set_sample_cubic", "surface_index", "cubic"), &PathMesh3D::set_sample_cubic);
    ClassDB::bind_method(D_METHOD("get_sample_cubic", "surface_index"), &PathMesh3D::get_sample_cubic);
    ClassDB::bind_method(D_METHOD("set_tilt", "surface_index", "tilt"), &PathMesh3D::set_tilt);
    ClassDB::bind_method(D_METHOD("get_tilt", "surface_index"), &PathMesh3D::get_tilt);
    ClassDB::bind_method(D_METHOD("set_offset", "surface_index", "offset"), &PathMesh3D::set_offset);
    ClassDB::bind_method(D_METHOD("get_offset", "surface_index"), &PathMesh3D::get_offset);

    ClassDB::bind_method(D_METHOD("set_mesh", "mesh"), &PathMesh3D::set_mesh);
    ClassDB::bind_method(D_METHOD("get_mesh"), &PathMesh3D::get_mesh);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "mesh", PROPERTY_HINT_RESOURCE_TYPE, "Mesh"), "set_mesh", "get_mesh");

    ClassDB::bind_method(D_METHOD("get_total_triangle_count"), &PathMesh3D::get_total_triangle_count);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "total_triangle_count", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY), "", "get_total_triangle_count");

    PATH_MESH_WITH_COLLISION_BINDS(PathMesh3D)
    
    ADD_SIGNAL(MethodInfo("mesh_changed"));

    BIND_ENUM_CONSTANT(DISTRIBUTE_BY_COUNT);
    BIND_ENUM_CONSTANT(DISTRIBUTE_BY_MODEL_LENGTH);
    BIND_ENUM_CONSTANT(ALIGN_STRETCH);
    BIND_ENUM_CONSTANT(ALIGN_FROM_START);
    BIND_ENUM_CONSTANT(ALIGN_CENTERED);
    BIND_ENUM_CONSTANT(ALIGN_FROM_END);
}

void PathMesh3D::_notification(int p_what) {
    switch (p_what) {
        case NOTIFICATION_READY: {
            set_process_internal(true);
            _rebuild_mesh();
        } break;

        case NOTIFICATION_INTERNAL_PROCESS: {
            if (_pop_is_dirty()) {
                _rebuild_mesh();
            } else if (collision_dirty) {
                _rebuild_collision_node();
            }
        } break;
    }
}

void PathMesh3D::_get_property_list(List<PropertyInfo> *p_list) const {
    for (uint64_t idx = 0; idx < surfaces.size(); ++idx) {
        const SurfaceData &surf = surfaces[idx];

        String surf_name = "surface_" + itos(idx);
        uint32_t usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_INTERNAL;
            
        p_list->push_back(PropertyInfo(
            Variant::NIL, surf_name.capitalize(), PROPERTY_HINT_NONE, surf_name + "/", PROPERTY_USAGE_GROUP));
        p_list->push_back(PropertyInfo(
                Variant::VECTOR3, surf_name + "/tile_rotation", PROPERTY_HINT_RANGE, "0.0,360.0,0.01,radians_as_degrees", usage));
        p_list->push_back(PropertyInfo(
                Variant::INT, surf_name + "/tile_rotation_order", PROPERTY_HINT_ENUM, "XYZ,XZY,YXZ,YZX,ZXY,ZYX", usage));
        p_list->push_back(PropertyInfo(
                Variant::INT, surf_name + "/distribution", PROPERTY_HINT_ENUM, "By Model Length,By Count", usage));
        p_list->push_back(PropertyInfo(
                Variant::INT, surf_name + "/alignment", PROPERTY_HINT_ENUM, "Stretch,From Start,Center,From End", usage));
        if (surf.distribution == Distribution::DISTRIBUTE_BY_COUNT) {
            String hint_str = "2," + itos(_get_max_count()) + ",1,or_greater";
            p_list->push_back(PropertyInfo(
                    Variant::INT, surf_name + "/count", PROPERTY_HINT_RANGE, hint_str, usage));
        }
        p_list->push_back(PropertyInfo(
                Variant::BOOL, surf_name + "/warp_along_curve", PROPERTY_HINT_NONE, "", usage));
        p_list->push_back(PropertyInfo(
                Variant::BOOL, surf_name + "/sample_cubic", PROPERTY_HINT_NONE, "", usage));
        p_list->push_back(PropertyInfo(
                Variant::BOOL, surf_name + "/tilt", PROPERTY_HINT_NONE, "", usage));
        p_list->push_back(PropertyInfo(
                Variant::VECTOR2, surf_name + "/offset", PROPERTY_HINT_NONE, "", usage));
        p_list->push_back(PropertyInfo(
                Variant::INT, surf_name + "/triangle_count", PROPERTY_HINT_NONE, "", usage | PROPERTY_USAGE_READ_ONLY));
    }
}

bool PathMesh3D::_property_can_revert(const StringName &p_name) const {
    if (p_name.begins_with("surface_")) {
        Pair<uint64_t, String> subprop = _decode_dynamic_propname(p_name);
        String sub_name = subprop.second;
        if (sub_name == "triangle_count") {
            return false;
        } else {
            return true; 
        }
    }

    return false;
}

bool PathMesh3D::_property_get_revert(const StringName &p_name, Variant &r_property) const {
    if (p_name.begins_with("surface_")) {
        Pair<uint64_t, String> subprop = _decode_dynamic_propname(p_name);
        uint64_t surf_idx = subprop.first;
        String sub_name = subprop.second;
        if (sub_name == "distribution") {
            r_property = Distribution::DISTRIBUTE_BY_MODEL_LENGTH;
        } else if (sub_name == "tile_rotation") {
            r_property = Vector3();
        } else if (sub_name == "tile_rotation_order") {
            r_property = EulerOrder::EULER_ORDER_YXZ;
        } else if (sub_name == "alignment") {
            r_property = Alignment::ALIGN_STRETCH;
        } else if (sub_name == "count") {
            r_property = 2;
        } else if (sub_name == "warp_along_curve") {
            r_property = true;
        } else if (sub_name == "sample_cubic") {
            r_property = false;
        } else if (sub_name == "tilt") {
            r_property = true;
        } else if (sub_name == "offset") {
            r_property = Vector2();
        } else {
            return false;
        }
        return true;
    }
    return false;
}

bool PathMesh3D::_set(const StringName &p_name, const Variant &p_property) {
    if (p_name.begins_with("surface_")) {
        Pair<uint64_t, String> subprop = _decode_dynamic_propname(p_name);
        uint64_t surf_idx = subprop.first;
        String sub_name = subprop.second;
        if (sub_name == "distribution") {
            set_distribution(surf_idx, Distribution(int(p_property)));
        } else if (sub_name == "tile_rotation") {
            set_tile_rotation(surf_idx, p_property);
        } else if (sub_name == "tile_rotation_order") {
            set_tile_rotation_order(surf_idx, EulerOrder(int(p_property)));
        } else if (sub_name == "alignment") {
            set_alignment(surf_idx, Alignment(int(p_property)));
        } else if (sub_name == "count") {
            set_count(surf_idx, p_property);
        } else if (sub_name == "warp_along_curve") {
            set_warp_along_curve(surf_idx, p_property);
        } else if (sub_name == "sample_cubic") {
            set_sample_cubic(surf_idx, p_property);
        } else if (sub_name == "tilt") {
            set_tilt(surf_idx, p_property);
        } else if (sub_name == "offset") {
            set_offset(surf_idx, p_property);
        } else {
            return false;
        }
        return true;
    }
    return false;
}

bool PathMesh3D::_get(const StringName &p_name, Variant &r_property) const {
    if (p_name.begins_with("surface_")) {
        Pair<uint64_t, String> subprop = _decode_dynamic_propname(p_name);
        uint64_t surf_idx = subprop.first;
        String sub_name = subprop.second;
        if (sub_name == "distribution") {
            r_property = get_distribution(surf_idx);
        } else if (sub_name == "tile_rotation") {
            r_property = get_tile_rotation(surf_idx);
        } else if (sub_name == "tile_rotation_order") {
            r_property = get_tile_rotation_order(surf_idx);
        } else if (sub_name == "alignment") {
            r_property = get_alignment(surf_idx);
        } else if (sub_name == "count") {
            r_property = get_count(surf_idx);
        } else if (sub_name == "warp_along_curve") {
            r_property = get_warp_along_curve(surf_idx);
        } else if (sub_name == "sample_cubic") {
            r_property = get_sample_cubic(surf_idx);
        } else if (sub_name == "tilt") {
            r_property = get_tilt(surf_idx);
        } else if (sub_name == "offset") {
            r_property = get_offset(surf_idx);
        } else if (sub_name == "triangle_count") {
            r_property = get_triangle_count(surf_idx);
        } else {
            return false;
        }
        return true;
    }
    return false;
}

void PathMesh3D::_rebuild_mesh() {
    generated_mesh->clear_surfaces();
    for (SurfaceData &surf : surfaces) {
        surf.n_tris = 0;
    }
    if (collision_node != nullptr) {
        remove_child(collision_node);
        collision_node->queue_free();
        collision_node = nullptr;
    }

    if (path3d == nullptr || path3d->get_curve().is_null() || !path3d->is_inside_tree() || source_mesh.is_null()) {
        return;
    }

    Transform3D mod_transform = _get_relative_transform();

    Ref<Curve3D> curve = path3d->get_curve();
    ERR_FAIL_COND_MSG(curve->get_point_count() < 2, "Curve has < 2 points, cannot tesselate.");

    double baked_l = curve->get_baked_length();
    ERR_FAIL_COND_MSG(baked_l == 0.0, "Curve has no length.");

    double mesh_l = _get_mesh_length();
    ERR_FAIL_COND_MSG(mesh_l == 0.0, "Provided mesh has no length in Z dimension.  Try rotating on X or Y to gain length.");
    ERR_FAIL_COND_MSG(baked_l < mesh_l, "Curve length < mesh length, cannot tile.");
    
    for (uint64_t idx_surf = 0; idx_surf < source_mesh->get_surface_count(); ++idx_surf) {
        SurfaceData &surf = surfaces[idx_surf];

        Array arrays = source_mesh->surface_get_arrays(idx_surf);

        PackedVector3Array old_verts = arrays[Mesh::ARRAY_VERTEX];

        LocalVector<bool> has_column;
        has_column.resize(Mesh::ARRAY_MAX);
        for (int idx_type = 0; idx_type < Mesh::ARRAY_MAX; ++idx_type) {
            has_column[idx_type] = arrays[idx_type].get_type() != Variant::NIL;
        }

        #define MAKE_OLD_ARRAY(m_type, m_name, m_index) \
            m_type m_name = has_column[m_index] ? m_type(arrays[m_index]) : m_type()
        MAKE_OLD_ARRAY(PackedVector3Array, old_norms, Mesh::ARRAY_NORMAL);
        MAKE_OLD_ARRAY(PackedFloat32Array, old_tang, Mesh::ARRAY_TANGENT);
        MAKE_OLD_ARRAY(PackedVector2Array, old_uv1, Mesh::ARRAY_TEX_UV);
        MAKE_OLD_ARRAY(PackedVector2Array, old_uv2, Mesh::ARRAY_TEX_UV2);
        MAKE_OLD_ARRAY(PackedColorArray, old_colors, Mesh::ARRAY_COLOR);
        MAKE_OLD_ARRAY(PackedByteArray, old_custom0, Mesh::ARRAY_CUSTOM0);
        MAKE_OLD_ARRAY(PackedByteArray, old_custom1, Mesh::ARRAY_CUSTOM1);
        MAKE_OLD_ARRAY(PackedByteArray, old_custom2, Mesh::ARRAY_CUSTOM2);
        MAKE_OLD_ARRAY(PackedByteArray, old_custom3, Mesh::ARRAY_CUSTOM3);
        MAKE_OLD_ARRAY(PackedInt32Array, old_bones /*my nickname in highschool*/, Mesh::ARRAY_BONES);
        MAKE_OLD_ARRAY(PackedFloat32Array, old_weights, Mesh::ARRAY_WEIGHTS);
        MAKE_OLD_ARRAY(PackedInt32Array, old_idx, Mesh::ARRAY_INDEX);
        #undef MAKE_OLD_ARRAY

        arrays.clear();

        // Transform the mesh according to user settings
        double pos_z = -INFINITY;
        for (uint64_t idx = 0; idx < old_verts.size(); ++idx) {
            Vector3 vert = old_verts[idx];

            Basis rot = Basis::from_euler(surf.tile_rotation, surf.tile_rotation_order);
            vert = rot.xform(vert);
            if (has_column[Mesh::ARRAY_NORMAL]) {
                Vector3 norm = old_norms[idx];
                norm = rot.xform(norm);
                old_norms[idx] = norm;
            }
            if (has_column[Mesh::ARRAY_TANGENT]) {
                Vector3 tang = Vector3(old_tang[idx*4], old_tang[idx*4 + 1], old_tang[idx*4 + 2]);
                tang = rot.xform(tang);
                old_tang[idx*4] = tang.x;
                old_tang[idx*4 + 1] = tang.y;
                old_tang[idx*4 + 2] = tang.z;
            }
            vert.x += surf.offset.x;
            vert.y += surf.offset.y;

            old_verts[idx] = vert;

            if (vert.z > pos_z) {
                pos_z = vert.z;
            }
        }

        uint64_t count = 2;
        uint64_t max_count = _get_max_count();
        switch (surf.distribution) {
            case Distribution::DISTRIBUTE_BY_COUNT: {
                count = Math::clamp(surf.count, uint64_t(2), max_count);
            } break;
            case Distribution::DISTRIBUTE_BY_MODEL_LENGTH: {
                count = max_count;
            } break;
            default:
                UtilityFunctions::push_error("Distribution type is incorrect.");
                continue;
        }

        double z_stretch = 1.0;
        double z = 0.0;
        switch (surf.alignment) {
            case Alignment::ALIGN_STRETCH: {
                if (surf.distribution == DISTRIBUTE_BY_MODEL_LENGTH) {
                    double real_l = mesh_l * count;
                    z_stretch = baked_l / real_l;
                } else {
                    z_stretch = baked_l / mesh_l / (count - 1);
                }
                z = pos_z * z_stretch;
            } break;
            case Alignment::ALIGN_FROM_START: {
                z_stretch = 1.0;
                z = pos_z;
            } break;
            case Alignment::ALIGN_CENTERED: {
                z_stretch = 1.0;
                double real_l = mesh_l * count;
                z = (baked_l - real_l) / 2.0 + pos_z;
            } break;
            case Alignment::ALIGN_FROM_END: {
                z_stretch = 1.0;
                double real_l = mesh_l * count;
                z = baked_l - real_l + pos_z;
            } break;
            default:
                UtilityFunctions::push_error("Alignment type is incorrect.");
                continue;
        }
        z_stretch = Math::max(z_stretch, 1.0);
        z = Math::clamp(z, 0.0, baked_l);

        uint64_t new_size = count * old_verts.size();
        PackedVector3Array new_verts; new_verts.resize(new_size);
        PackedVector3Array new_norms; new_norms.resize(new_size);
        PackedFloat32Array new_tang; new_tang.resize(new_size*4);
        PackedVector2Array new_uv1;
        PackedVector2Array new_uv2;
        PackedColorArray new_colors;
        PackedByteArray new_custom0;
        PackedByteArray new_custom1;
        PackedByteArray new_custom2;
        PackedByteArray new_custom3;
        PackedInt32Array new_bones;
        PackedFloat32Array new_weights;
        PackedInt32Array new_idx;

        uint64_t k = 0; // overall index into new arrays

        for (uint64_t idx_count = 0; idx_count < count; ++idx_count) {
            Transform3D transform;
            if (!surf.warp_along_curve) {
                transform = curve->sample_baked_with_rotation(z, surf.cubic, surf.tilt) * 
                        _sample_3d_modifiers_at(z / baked_l);
            }

            for (uint64_t idx_vert = 0; idx_vert < old_verts.size(); ++idx_vert) {
                Vector3 vertex;
                if (surf.warp_along_curve) {
                    double z_offset = z - z_stretch * old_verts[idx_vert].z;
                    transform = curve->sample_baked_with_rotation(z_offset, surf.cubic, surf.tilt) * 
                            _sample_3d_modifiers_at(z_offset / baked_l);
                    
                    // Avoid double transforming the Z position by zeroing out the original Z value
                    vertex = { old_verts[idx_vert].x, old_verts[idx_vert].y, 0.0 };
                } else {
                    // No need to recalculate the transform if not warping
                    vertex = old_verts[idx_vert];
                }
                
                Transform3D final_transform = relative_transform == TRANSFORM_MESH_PATH_NODE ? mod_transform * transform : transform;

                new_verts[k] = final_transform.xform(vertex);
                if (has_column[Mesh::ARRAY_NORMAL]) {
                    new_norms[k] = final_transform.basis.xform(old_norms[idx_vert]);
                }
                if (has_column[Mesh::ARRAY_TANGENT]) {
                    Vector3 tang = final_transform.basis.xform(Vector3(old_tang[idx_vert*4], old_tang[idx_vert*4 + 1], old_tang[idx_vert*4 + 2]));
                    new_tang[k*4] = tang.x;
                    new_tang[k*4 + 1] = tang.y;
                    new_tang[k*4 + 2] = tang.z;
                    new_tang[k*4 + 3] = old_tang[idx_vert*4 + 3];
                }

                k++;
            }

            new_uv1.append_array(old_uv1);
            new_uv2.append_array(old_uv2);
            new_colors.append_array(old_colors);
            new_custom0.append_array(old_custom0);
            new_custom1.append_array(old_custom1);
            new_custom2.append_array(old_custom2);
            new_custom3.append_array(old_custom3);
            new_bones.append_array(old_bones);
            new_weights.append_array(old_weights);
            new_idx.append_array(old_idx);
            for (int32_t &idx : old_idx) {
                idx += old_verts.size(); // increase the indices by size each loop
            }
            
            z += mesh_l * z_stretch;
        }

        arrays.resize(Mesh::ARRAY_MAX);
        arrays.fill(Variant());
        arrays[Mesh::ARRAY_VERTEX] = new_verts;
        #define MAKE_NEW_ARRAY(m_index, m_name) arrays[m_index] = m_name.is_empty() ? Variant() : Variant(m_name)
        MAKE_NEW_ARRAY(Mesh::ARRAY_NORMAL, new_norms);
        MAKE_NEW_ARRAY(Mesh::ARRAY_TANGENT, new_tang);
        MAKE_NEW_ARRAY(Mesh::ARRAY_TEX_UV, new_uv1);
        MAKE_NEW_ARRAY(Mesh::ARRAY_TEX_UV2, new_uv2);
        MAKE_NEW_ARRAY(Mesh::ARRAY_COLOR, new_colors);
        MAKE_NEW_ARRAY(Mesh::ARRAY_CUSTOM0, new_custom0);
        MAKE_NEW_ARRAY(Mesh::ARRAY_CUSTOM1, new_custom1);
        MAKE_NEW_ARRAY(Mesh::ARRAY_CUSTOM2, new_custom2);
        MAKE_NEW_ARRAY(Mesh::ARRAY_CUSTOM3, new_custom3);
        MAKE_NEW_ARRAY(Mesh::ARRAY_BONES, new_bones);
        MAKE_NEW_ARRAY(Mesh::ARRAY_WEIGHTS, new_weights);
        MAKE_NEW_ARRAY(Mesh::ARRAY_INDEX, new_idx);
        #undef MAKE_NEW_ARRAY

        Mesh::PrimitiveType primitives = Mesh::PRIMITIVE_TRIANGLES;
        Ref<ArrayMesh> arr_mesh = cast_to<ArrayMesh>(source_mesh.ptr());
        if (arr_mesh != nullptr) {
            primitives = arr_mesh->surface_get_primitive_type(idx_surf);
        }

        generated_mesh->add_surface_from_arrays(primitives, arrays, source_mesh->surface_get_blend_shape_arrays(idx_surf));
        generated_mesh->surface_set_material(idx_surf, source_mesh->surface_get_material(idx_surf));

        surf.n_tris = new_verts.size() / 3;
    }

    _rebuild_collision_node();
}

Pair<uint64_t, String> PathMesh3D::_decode_dynamic_propname(const StringName &p_name) const {
    PackedStringArray prop_path = p_name.split("/");
    if (prop_path.size() != 2) {
        return Pair<uint64_t, String>();
    }

    uint64_t surf_idx = prop_path[0].trim_prefix("surface_").to_int();
    String sub_name = prop_path[1];
    return Pair(surf_idx, sub_name);
}

double PathMesh3D::_get_mesh_length() const {
    if (source_mesh.is_valid()) {
        double min_z = 0;
        double max_z = 0;
        for (uint64_t idx_surf = 0; idx_surf < source_mesh->get_surface_count(); ++idx_surf) {
            SurfaceData surf = surfaces[idx_surf];

            Array mesh_array = source_mesh->surface_get_arrays(idx_surf);
            PackedVector3Array verts = mesh_array[Mesh::ARRAY_VERTEX];
        
            for (uint64_t idx = 0; idx < verts.size(); ++idx) {
                Vector3 vert = verts[idx];
                Basis rot = Basis::from_euler(surf.tile_rotation, surf.tile_rotation_order);
                vert = rot.xform(vert);
                if (vert.z < min_z) {
                    min_z = vert.z;
                } else if (vert.z > max_z) {
                    max_z = vert.z;
                }
            }
        }
        return Math::absd(max_z - min_z);
    } else {
        return 1.0;
    }
}

uint64_t PathMesh3D::_get_max_count() const {
    if (source_mesh.is_valid() && path3d != nullptr && path3d->get_curve().is_valid()) {
        return path3d->get_curve()->get_baked_length() / _get_mesh_length();
    } else {
        return 100;
    }
}

void PathMesh3D::_on_mesh_changed() {
    if (source_mesh.is_valid()) {
        surfaces.resize(source_mesh->get_surface_count());
    } else {
        surfaces.clear();
    }
    emit_signal("mesh_changed");
    queue_rebuild();
    notify_property_list_changed();
}

PathMesh3D::PathMesh3D() {
    generated_mesh.instantiate();
    set_base(generated_mesh->get_rid());
}

PathMesh3D::~PathMesh3D() {
    PATH_TOOL_DESTRUCTOR(PathMesh3D)
    
    if (source_mesh.is_valid()) {
        if (source_mesh->is_connected("changed", callable_mp(this, &PathMesh3D::_on_mesh_changed))) {
            source_mesh->disconnect("changed", callable_mp(this, &PathMesh3D::_on_mesh_changed));
        }
        source_mesh.unref();
    }
    if (path3d != nullptr) {
        if (UtilityFunctions::is_instance_id_valid(path3d->get_instance_id()) && 
                path3d->is_connected("curve_changed", callable_mp(this, &PathMesh3D::_on_curve_changed))) {
            path3d->disconnect("curve_changed", callable_mp(this, &PathMesh3D::_on_curve_changed));
        }
        path3d = nullptr;
    }
    if (collision_node != nullptr) {
        collision_node->queue_free();
        collision_node = nullptr;
    }
    generated_mesh->clear_surfaces();
    generated_mesh.unref();
    surfaces.clear();
}