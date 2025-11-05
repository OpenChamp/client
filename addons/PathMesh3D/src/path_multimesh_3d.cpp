#include <godot_cpp/classes/curve3d.hpp>

#include "path_multimesh_3d.hpp"


using namespace godot;

void PathMultiMesh3D::set_multi_mesh(const Ref<MultiMesh> &p_multi_mesh) {
    if (p_multi_mesh != multi_mesh) {
        if (multi_mesh.is_valid() && multi_mesh->is_connected("changed", callable_mp(this, &PathMultiMesh3D::_on_mesh_changed))) {
            multi_mesh->disconnect("changed", callable_mp(this, &PathMultiMesh3D::_on_mesh_changed));
        }

        multi_mesh = p_multi_mesh;

        if (multi_mesh.is_valid()) {
            set_base(multi_mesh->get_rid());
            multi_mesh->connect("changed", callable_mp(this, &PathMultiMesh3D::_on_mesh_changed));
            _on_mesh_changed();
        } else {
            set_base(RID());
        }

        notify_property_list_changed();
    }
}

Ref<MultiMesh> PathMultiMesh3D::get_multi_mesh() const {
    return multi_mesh;
}

void PathMultiMesh3D::set_distribution(Distribution p_distribution) {
    if (distribution != p_distribution) {
        distribution = p_distribution;
        queue_rebuild();
        notify_property_list_changed();
    }
}

auto PathMultiMesh3D::get_distribution() const -> Distribution{
    return distribution;
}

void PathMultiMesh3D::set_alignment(Alignment p_alignment) {
    if (alignment != p_alignment) {
        alignment = p_alignment;
        if (distribution != DISTRIBUTE_BY_COUNT) {
            queue_rebuild();
        }
    }
}

auto PathMultiMesh3D::get_alignment() const -> Alignment{
    return alignment;
}

void PathMultiMesh3D::set_count(uint64_t p_count) {
    if (count != p_count) {
        count = Math::max(p_count, uint64_t(0));
        if (distribution == DISTRIBUTE_BY_COUNT) {
            queue_rebuild();
        }
    }
}

uint64_t PathMultiMesh3D::get_count() const {
    return count;
}

void PathMultiMesh3D::set_distance(double p_distance) {
    if (distance != p_distance) {
        distance = Math::max(p_distance, 0.01);
        if (distribution == DISTRIBUTE_BY_DISTANCE) {
            queue_rebuild();
        }
    }
}

double PathMultiMesh3D::get_distance() const {
    return distance;
}

void PathMultiMesh3D::set_rotation_mode(Rotation p_rotation_mode) {
    if (rotation_mode != p_rotation_mode) {
        rotation_mode = p_rotation_mode;
        queue_rebuild();
        notify_property_list_changed();
    }
}

void PathMultiMesh3D::set_rotation(const Vector3 &p_rotation) {
    if (rotation != p_rotation) {
        rotation = p_rotation;
        queue_rebuild();
    }
}

Vector3 PathMultiMesh3D::get_rotation() const {
    return rotation;
}

auto PathMultiMesh3D::get_rotation_mode() const -> Rotation{
    return rotation_mode;
}

void PathMultiMesh3D::set_sample_cubic(bool p_cubic) {
    if (sample_cubic != p_cubic) {
        sample_cubic = p_cubic;
        queue_rebuild();
    }
}

bool PathMultiMesh3D::get_sample_cubic() const {
    return sample_cubic;
}

void PathMultiMesh3D::_bind_methods() {
    PATH_TOOL_BINDS(PathMultiMesh3D, mesh, MESH)

    ClassDB::bind_method(D_METHOD("set_multi_mesh", "multi_mesh"), &PathMultiMesh3D::set_multi_mesh);
    ClassDB::bind_method(D_METHOD("get_multi_mesh"), &PathMultiMesh3D::get_multi_mesh);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "multi_mesh", PROPERTY_HINT_RESOURCE_TYPE, "MultiMesh"), "set_multi_mesh", "get_multi_mesh");

    ClassDB::bind_method(D_METHOD("set_distribution", "distribution"), &PathMultiMesh3D::set_distribution);
    ClassDB::bind_method(D_METHOD("get_distribution"), &PathMultiMesh3D::get_distribution);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "distribution", PROPERTY_HINT_ENUM, "By Count,By Distance"), "set_distribution", "get_distribution");

    ClassDB::bind_method(D_METHOD("set_alignment", "alignment"), &PathMultiMesh3D::set_alignment);
    ClassDB::bind_method(D_METHOD("get_alignment"), &PathMultiMesh3D::get_alignment);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "alignment", PROPERTY_HINT_ENUM, "From Start,Centered,From End"), "set_alignment", "get_alignment");

    ClassDB::bind_method(D_METHOD("set_count", "count"), &PathMultiMesh3D::set_count);
    ClassDB::bind_method(D_METHOD("get_count"), &PathMultiMesh3D::get_count);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "count", PROPERTY_HINT_RANGE, "1,1000000,1,or_greater"), "set_count", "get_count");

    ClassDB::bind_method(D_METHOD("set_distance", "distance"), &PathMultiMesh3D::set_distance);
    ClassDB::bind_method(D_METHOD("get_distance"), &PathMultiMesh3D::get_distance);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "distance", PROPERTY_HINT_RANGE, "0.01,1000000.0,0.01,or_greater"), "set_distance", "get_distance");

    ClassDB::bind_method(D_METHOD("set_rotation_mode", "rotation_mode"), &PathMultiMesh3D::set_rotation_mode);
    ClassDB::bind_method(D_METHOD("get_rotation_mode"), &PathMultiMesh3D::get_rotation_mode);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "rotation_mode", PROPERTY_HINT_ENUM, "Fixed,Path,Random"), "set_rotation_mode", "get_rotation_mode");

    ClassDB::bind_method(D_METHOD("set_rotation", "rotation"), &PathMultiMesh3D::set_rotation);
    ClassDB::bind_method(D_METHOD("get_rotation"), &PathMultiMesh3D::get_rotation);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "rotation", PROPERTY_HINT_RANGE, "0.0,360.0,0.01,radians_as_degrees"), "set_rotation", "get_rotation");

    ClassDB::bind_method(D_METHOD("set_sample_cubic", "sample_cubic"), &PathMultiMesh3D::set_sample_cubic);
    ClassDB::bind_method(D_METHOD("get_sample_cubic"), &PathMultiMesh3D::get_sample_cubic);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "sample_cubic"), "set_sample_cubic", "get_sample_cubic");

    ADD_SIGNAL(MethodInfo("mesh_changed"));

    BIND_ENUM_CONSTANT(DISTRIBUTE_BY_COUNT);
    BIND_ENUM_CONSTANT(DISTRIBUTE_BY_DISTANCE);
    BIND_ENUM_CONSTANT(DISTRIBUTE_MAX);
    BIND_ENUM_CONSTANT(ROTATE_FIXED);
    BIND_ENUM_CONSTANT(ROTATE_PATH);
    BIND_ENUM_CONSTANT(ROTATE_RANDOM);
    BIND_ENUM_CONSTANT(ROTATE_MAX);
    BIND_ENUM_CONSTANT(ALIGN_FROM_START);
    BIND_ENUM_CONSTANT(ALIGN_CENTERED);
    BIND_ENUM_CONSTANT(ALIGN_FROM_END);
    BIND_ENUM_CONSTANT(ALIGN_MAX);
}

void PathMultiMesh3D::_notification(int p_what) {
    switch (p_what) {
        case NOTIFICATION_READY: {
            set_process_internal(true);
            _rebuild_mesh();
        } break;

        case NOTIFICATION_INTERNAL_PROCESS: {
            if (_pop_is_dirty()) {
                _rebuild_mesh();
            }
        } break;
    }
}

void PathMultiMesh3D::_validate_property(PropertyInfo &property) const {
    if (property.name == StringName("count") && distribution != DISTRIBUTE_BY_COUNT) {
        property.usage = PROPERTY_USAGE_STORAGE;
    } else if (property.name == StringName("rotation") && rotation_mode == ROTATE_RANDOM) {
        property.usage = PROPERTY_USAGE_STORAGE;
    } else if (property.name == StringName("alignment") && distribution == DISTRIBUTE_BY_COUNT) {
        property.usage = PROPERTY_USAGE_STORAGE;
    } else if (property.name == StringName("distance") && distribution != DISTRIBUTE_BY_DISTANCE) {
        property.usage = PROPERTY_USAGE_STORAGE;
    }
}

void PathMultiMesh3D::_on_mesh_changed() {
    emit_signal("mesh_changed");
    queue_rebuild();
}

void PathMultiMesh3D::_rebuild_mesh() {
    if (multi_mesh.is_null()) {
        return;
    }
    multi_mesh->set_instance_count(0);

    if (path3d == nullptr || path3d->get_curve().is_null() || !path3d->is_inside_tree()) {
        return;
    }

    Transform3D mod_transform = _get_relative_transform();

    Ref<Curve3D> curve = path3d->get_curve();
    if (curve->get_point_count() < 2) {
        return;
    }

    double baked_l = curve->get_baked_length();

    if (baked_l == 0.0) {
        return;
    }

    uint64_t n_instances = 0;
    double separation = 0.0;
    switch (distribution) {
        case DISTRIBUTE_BY_COUNT: {
            n_instances = count;
            separation = baked_l / (count - 1);
        } break;
        case DISTRIBUTE_BY_DISTANCE: {
            separation = distance;
            n_instances = Math::floor(baked_l / separation) + 1;
        } break;
        default:
            ERR_FAIL();
    }

    double offset = 0.0;
    if (distribution != DISTRIBUTE_BY_COUNT) {
        switch (alignment) {
            case ALIGN_FROM_START: {
                offset = 0.0;
            } break;
            case ALIGN_CENTERED: {
                offset = (baked_l - separation * (n_instances - 1)) * 0.5;
            } break;
            case ALIGN_FROM_END: {
                offset = baked_l - separation * (n_instances - 1);
            } break;
            default:
                ERR_FAIL();
        }
    }

    multi_mesh->set_transform_format(MultiMesh::TRANSFORM_3D);
    multi_mesh->set_instance_count(n_instances);

    for (uint64_t i = 0; i < n_instances; ++i) {
        Transform3D transform;
        switch (rotation_mode) {
            case ROTATE_FIXED: {
                transform.origin = curve->sample_baked(offset, sample_cubic);
                transform.basis = Basis::from_euler(rotation);
            } break;
            case ROTATE_PATH: {
                transform = curve->sample_baked_with_rotation(offset, sample_cubic, true);
                transform.basis.rotate(rotation);
            } break;
            case ROTATE_RANDOM: {
                transform = curve->sample_baked_with_rotation(offset, sample_cubic, true);
                transform.basis.rotate(Vector3(0.0, 1.0, 0.0), UtilityFunctions::randf_range(0.0, Math_TAU));
            } break;
            default:
                ERR_FAIL();
        }

        transform *= _sample_3d_modifiers_at(offset / baked_l);

        if (relative_transform == TRANSFORM_MESH_PATH_NODE) {
            transform = mod_transform * transform;
        }

        multi_mesh->set_instance_transform(i, transform);
        offset += separation;
    }
}

PathMultiMesh3D::~PathMultiMesh3D() {
    PATH_TOOL_DESTRUCTOR(PathMultiMesh3D)
    
    if (multi_mesh.is_valid()) {
        if (multi_mesh->is_connected("changed", callable_mp(this, &PathMultiMesh3D::_on_mesh_changed))) {
            multi_mesh->disconnect("changed", callable_mp(this, &PathMultiMesh3D::_on_mesh_changed));
        }
        multi_mesh.unref();
    }
}