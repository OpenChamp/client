#include <godot_cpp/classes/curve3d.hpp>

#include "path_tool.hpp"
#include "path_modifier_3d.hpp"
#include "path_mesh_3d.hpp"
#include "path_extrude_3d.hpp"
#include "path_multimesh_3d.hpp"
#include "path_scene_3d.hpp"

using namespace godot;

void PathModifier3D::set_curve_offset_start(real_t p_offset) {
    if (tool != nullptr) {
        const Ref<Curve3D> &path_curve = tool->get_curve_3d();
        if (path_curve.is_valid() && path_curve->get_baked_length() > 0.0) {
            set_curve_offset_ratio_start(p_offset / path_curve->get_baked_length());
        }
    }
}

real_t PathModifier3D::get_curve_offset_start() const {
    real_t r_value = 0.0;

    if (tool != nullptr) {
        const Ref<Curve3D> &path_curve = tool->get_curve_3d();
        if (path_curve.is_valid()) {
            r_value = get_curve_offset_ratio_start() * path_curve->get_baked_length();
        }
    }

    return r_value;
}

void PathModifier3D::set_curve_offset_end(real_t p_offset) {
    if (tool != nullptr) {
        const Ref<Curve3D> &path_curve = tool->get_curve_3d();
        if (path_curve.is_valid() && path_curve->get_baked_length() > 0.0) {
            set_curve_offset_ratio_end(p_offset / path_curve->get_baked_length());
        }
    }
}

real_t PathModifier3D::get_curve_offset_end() const {
    real_t r_value = 0.0;
    
    if (tool != nullptr) {
        const Ref<Curve3D> &path_curve = tool->get_curve_3d();
        if (path_curve.is_valid()) {
            r_value = get_curve_offset_ratio_end() * path_curve->get_baked_length();
        }
    }

    return r_value;
}

void PathModifier3D::set_curve_offset_ratio_start(real_t p_offset_ratio) {
    p_offset_ratio = Math::clamp(p_offset_ratio, real_t(0.0), curve_offset_ratio_end);
    if (p_offset_ratio != curve_offset_ratio_start) {
        curve_offset_ratio_start = p_offset_ratio;
        queue_rebuild();
    }
}

real_t PathModifier3D::get_curve_offset_ratio_start() const {
    return curve_offset_ratio_start;
}

void PathModifier3D::set_curve_offset_ratio_end(real_t p_offset_ratio) {
    p_offset_ratio = Math::clamp(p_offset_ratio, curve_offset_ratio_start, real_t(1.0));
    if (p_offset_ratio != curve_offset_ratio_end) {
        curve_offset_ratio_end = p_offset_ratio;
        queue_rebuild();
    }
}

real_t PathModifier3D::get_curve_offset_ratio_end() const {
    return curve_offset_ratio_end;
}

void PathModifier3D::set_influence(const Ref<Curve> &p_curve) {
    if (p_curve != influence) {
        Callable callback = callable_mp(this, &PathModifier3D::_on_influence_changed);

        if (influence.is_valid() && influence->is_connected("changed", callback)) {
            influence->disconnect("changed", callback);
        }

        influence = p_curve;

        if (influence.is_valid() && !influence->is_connected("changed", callback)) {
            influence->connect("changed", callback);
        }

        callback.call();
    }
}

Ref<Curve> PathModifier3D::get_influence() const {
    return influence;
}

void PathModifier3D::set_position_modifier(Vector3 p_modifier) {
    if (p_modifier != position_modifier) {
        position_modifier = p_modifier;
        queue_rebuild();
    }
}

Vector3 PathModifier3D::get_position_modifier() const {
    return position_modifier;
}

void PathModifier3D::set_position_randomness(Vector3 p_randomness) {
    if (p_randomness != position_randomness) {
        position_randomness = p_randomness;
        queue_rebuild();
    }
}

Vector3 PathModifier3D::get_position_randomness() const {
    return position_randomness;
}

void PathModifier3D::set_rotation_modifier_mode(RotationEditMode p_mode) {
    if (p_mode != rotation_modifier_mode) {
        rotation_modifier_mode = p_mode;
        notify_property_list_changed();
    }
}

Node3D::RotationEditMode PathModifier3D::get_rotation_modifier_mode() const {
    return rotation_modifier_mode;
}

void PathModifier3D::set_rotation_modifier(const Variant &p_modifier) {
    switch (p_modifier.get_type()) {
        case Variant::BASIS: {
            set_rotation_modifier_t<Basis>(p_modifier);
        } break;
        case Variant::QUATERNION: {
            set_rotation_modifier_t<Quaternion>(p_modifier);
        } break;
        case Variant::VECTOR3: {
            set_rotation_modifier_t<Vector3>(p_modifier);
        } break;
        default:
            ERR_FAIL_MSG("Invalid rotation modifier type.");
    }
}

Variant PathModifier3D::get_rotation_modifier() const {
    switch (rotation_modifier_mode) {
        case ROTATION_EDIT_MODE_BASIS: {
            return get_rotation_modifier_t<Basis>();
        } break;
        case ROTATION_EDIT_MODE_QUATERNION: {
            return get_rotation_modifier_t<Quaternion>();
        } break;
        case ROTATION_EDIT_MODE_EULER: {
            return get_rotation_modifier_t<Vector3>();
        } break;
        default:
            ERR_FAIL_V(Variant());
    }
}

void PathModifier3D::set_rotation_randomness(const Variant &p_randomness) {
    switch (p_randomness.get_type()) {
        case Variant::BASIS: {
            set_rotation_randomness_t<Basis>(p_randomness);
        } break;
        case Variant::QUATERNION: {
            set_rotation_randomness_t<Quaternion>(p_randomness);
        } break;
        case Variant::VECTOR3: {
            set_rotation_randomness_t<Vector3>(p_randomness);
        } break;
        default:
            ERR_FAIL_MSG("Invalid rotation randomness type.");
    }
}

Variant PathModifier3D::get_rotation_randomness() const {
    switch (rotation_modifier_mode) {
        case ROTATION_EDIT_MODE_BASIS: {
            return get_rotation_randomness_t<Basis>();
        } break;
        case ROTATION_EDIT_MODE_QUATERNION: {
            return get_rotation_randomness_t<Quaternion>();
        } break;
        case ROTATION_EDIT_MODE_EULER: {
            return get_rotation_randomness_t<Vector3>();
        } break;
        default:
            ERR_FAIL_V(Variant());
    }
}

void PathModifier3D::set_scale_modifier(Vector3 p_modifier) {
    if (p_modifier != scale_modifier) {
        scale_modifier = p_modifier;
        queue_rebuild();
    }
}

Vector3 PathModifier3D::get_scale_modifier() const {
    return scale_modifier;
}

void PathModifier3D::set_scale_randomness(Vector3 p_randomness) {
    if (p_randomness != scale_randomness) {
        scale_randomness = p_randomness;
        queue_rebuild();
    }
}

Vector3 PathModifier3D::get_scale_randomness() const {
    return scale_randomness;
}

void PathModifier3D::set_uv_offset_modifier(Vector2 p_modifier) {
    if (p_modifier != uv_offset_modifier) {
        uv_offset_modifier = p_modifier;
        queue_rebuild();
    }
}

Vector2 PathModifier3D::get_uv_offset_modifier() const {
    return uv_offset_modifier;
}

void PathModifier3D::set_uv_offset_randomness(Vector2 p_randomness) {
    if (p_randomness != uv_offset_randomness) {
        uv_offset_randomness = p_randomness;
        queue_rebuild();
    }
}

Vector2 PathModifier3D::get_uv_offset_randomness() const {
    return uv_offset_randomness;
}

void PathModifier3D::set_uv_scale_modifier(Vector2 p_modifier) {
    if (p_modifier != uv_scale_modifier) {
        uv_scale_modifier = p_modifier;
        queue_rebuild();
    }
}

Vector2 PathModifier3D::get_uv_scale_modifier() const {
    return uv_scale_modifier;
}

void PathModifier3D::set_uv_scale_randomness(Vector2 p_randomness) {
    if (p_randomness != uv_scale_randomness) {
        uv_scale_randomness = p_randomness;
        queue_rebuild();
    }
}

Vector2 PathModifier3D::get_uv_scale_randomness() const {
    return uv_scale_randomness;
}

Transform3D PathModifier3D::sample_3d_modifier_at(real_t p_offset_ratio) const {
    real_t y = _sample_influence(p_offset_ratio);
    if (y == 0.0) {
        return Transform3D();
    }

    Vector3 position = Vector3(0.0, 0.0, 0.0).lerp((position_modifier + UtilityFunctions::randf_range(-1.0, 1.0) * position_randomness), y);
    Quaternion rotation = Quaternion().slerpni(rotation_modifier * Quaternion().slerpni(rotation_randomness, UtilityFunctions::randf()), y);
    Vector3 scale = Vector3(1.0, 1.0, 1.0).lerp(scale_modifier + UtilityFunctions::randf() * scale_randomness, y);

    return Transform3D(Basis(rotation).scaled(scale), position);
}

Transform2D PathModifier3D::sample_uv_modifier_at(real_t p_offset_ratio) const {
    real_t y = _sample_influence(p_offset_ratio);
    if (y == 0.0) {
        return Transform2D();
    }

    Vector2 offset = Vector2(0.0, 0.0).lerp(uv_offset_modifier + UtilityFunctions::randf_range(-1.0, 1.0) * uv_offset_randomness, y);
    Vector2 scale = Vector2(1.0, 1.0).lerp(uv_scale_modifier + UtilityFunctions::randf_range(-1.0, 1.0) * uv_scale_randomness, y);

    return Transform2D(0.0, scale, 0.0, offset);
}

void PathModifier3D::queue_rebuild() {
    dirty = true;
}

bool PathModifier3D::pop_is_dirty() {
    bool is_dirty = dirty;
    dirty = false;
    return is_dirty;
}

void PathModifier3D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_curve_offset_start", "offset"), &PathModifier3D::set_curve_offset_start);
    ClassDB::bind_method(D_METHOD("get_curve_offset_start"), &PathModifier3D::get_curve_offset_start);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "curve_offset_start"), "set_curve_offset_start", "get_curve_offset_start");
    
    ClassDB::bind_method(D_METHOD("set_curve_offset_end", "offset"), &PathModifier3D::set_curve_offset_end);
    ClassDB::bind_method(D_METHOD("get_curve_offset_end"), &PathModifier3D::get_curve_offset_end);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "curve_offset_end"), "set_curve_offset_end", "get_curve_offset_end");

    ClassDB::bind_method(D_METHOD("set_curve_offset_ratio_start", "offset_ratio"), &PathModifier3D::set_curve_offset_ratio_start);
    ClassDB::bind_method(D_METHOD("get_curve_offset_ratio_start"), &PathModifier3D::get_curve_offset_ratio_start);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "curve_offset_ratio_start"), "set_curve_offset_ratio_start", "get_curve_offset_ratio_start");
    
    ClassDB::bind_method(D_METHOD("set_curve_offset_ratio_end", "offset_ratio"), &PathModifier3D::set_curve_offset_ratio_end);
    ClassDB::bind_method(D_METHOD("get_curve_offset_ratio_end"), &PathModifier3D::get_curve_offset_ratio_end);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "curve_offset_ratio_end"), "set_curve_offset_ratio_end", "get_curve_offset_ratio_end");

    ClassDB::bind_method(D_METHOD("set_influence", "influence_curve"), &PathModifier3D::set_influence);
    ClassDB::bind_method(D_METHOD("get_influence"), &PathModifier3D::get_influence);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "influence", PROPERTY_HINT_RESOURCE_TYPE, "Curve"), "set_influence", "get_influence");

    ClassDB::bind_method(D_METHOD("set_position_modifier", "modifier"), &PathModifier3D::set_position_modifier);
    ClassDB::bind_method(D_METHOD("get_position_modifier"), &PathModifier3D::get_position_modifier);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "position_modifier"), "set_position_modifier", "get_position_modifier");
    
    ClassDB::bind_method(D_METHOD("set_position_randomness", "randomness"), &PathModifier3D::set_position_randomness);
    ClassDB::bind_method(D_METHOD("get_position_randomness"), &PathModifier3D::get_position_randomness);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "position_randomness"), "set_position_randomness", "get_position_randomness");

    ClassDB::bind_method(D_METHOD("_set_rotation_modifier_mode", "modifier"), &PathModifier3D::set_rotation_modifier_mode);
    ClassDB::bind_method(D_METHOD("_get_rotation_modifier_mode"), &PathModifier3D::get_rotation_modifier_mode);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "rotation_modifier_mode", PROPERTY_HINT_ENUM, "Euler,Quaternion,Basis", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_INTERNAL), "_set_rotation_modifier_mode", "_get_rotation_modifier_mode");

    ClassDB::bind_method(D_METHOD("set_rotation_modifier", "modifier"), &PathModifier3D::set_rotation_modifier);
    ClassDB::bind_method(D_METHOD("get_rotation_modifier"), &PathModifier3D::get_rotation_modifier);
    ADD_PROPERTY(PropertyInfo(Variant::NIL, "rotation_modifier"), "set_rotation_modifier", "get_rotation_modifier");

    ClassDB::bind_method(D_METHOD("set_rotation_randomness", "randomness"), &PathModifier3D::set_rotation_randomness);
    ClassDB::bind_method(D_METHOD("get_rotation_randomness"), &PathModifier3D::get_rotation_randomness);
    ADD_PROPERTY(PropertyInfo(Variant::NIL, "rotation_randomness"), "set_rotation_randomness", "get_rotation_randomness");

    ClassDB::bind_method(D_METHOD("set_scale_modifier", "modifier"), &PathModifier3D::set_scale_modifier);
    ClassDB::bind_method(D_METHOD("get_scale_modifier"), &PathModifier3D::get_scale_modifier);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "scale_modifier", PROPERTY_HINT_LINK), "set_scale_modifier", "get_scale_modifier");
    
    ClassDB::bind_method(D_METHOD("set_scale_randomness", "randomness"), &PathModifier3D::set_scale_randomness);
    ClassDB::bind_method(D_METHOD("get_scale_randomness"), &PathModifier3D::get_scale_randomness);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "scale_randomness", PROPERTY_HINT_LINK), "set_scale_randomness", "get_scale_randomness");
    
    ClassDB::bind_method(D_METHOD("set_uv_offset_modifier", "modifier"), &PathModifier3D::set_uv_offset_modifier);
    ClassDB::bind_method(D_METHOD("get_uv_offset_modifier"), &PathModifier3D::get_uv_offset_modifier);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "uv_offset_modifier"), "set_uv_offset_modifier", "get_uv_offset_modifier");

    ClassDB::bind_method(D_METHOD("set_uv_offset_randomness", "randomness"), &PathModifier3D::set_uv_offset_randomness);
    ClassDB::bind_method(D_METHOD("get_uv_offset_randomness"), &PathModifier3D::get_uv_offset_randomness);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "uv_offset_randomness"), "set_uv_offset_randomness", "get_uv_offset_randomness");

    ClassDB::bind_method(D_METHOD("set_uv_scale_modifier", "modifier"), &PathModifier3D::set_uv_scale_modifier);
    ClassDB::bind_method(D_METHOD("get_uv_scale_modifier"), &PathModifier3D::get_uv_scale_modifier);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "uv_scale_modifier", PROPERTY_HINT_LINK), "set_uv_scale_modifier", "get_uv_scale_modifier");

    ClassDB::bind_method(D_METHOD("set_uv_scale_randomness", "randomness"), &PathModifier3D::set_uv_scale_randomness);
    ClassDB::bind_method(D_METHOD("get_uv_scale_randomness"), &PathModifier3D::get_uv_scale_randomness);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "uv_scale_randomness", PROPERTY_HINT_LINK), "set_uv_scale_randomness", "get_uv_scale_randomness");

    ClassDB::bind_method(D_METHOD("sample_3d_modifier_at", "offset_ratio"), &PathModifier3D::sample_3d_modifier_at);
    ClassDB::bind_method(D_METHOD("sample_uv_modifier_at", "offset_ratio"), &PathModifier3D::sample_uv_modifier_at);

    BIND_ENUM_CONSTANT(ROTATION_EDIT_MODE_EULER);
    BIND_ENUM_CONSTANT(ROTATION_EDIT_MODE_QUATERNION);
    BIND_ENUM_CONSTANT(ROTATION_EDIT_MODE_BASIS);
}

void PathModifier3D::_notification(int p_what) {
    switch (p_what) {
        case NOTIFICATION_POST_ENTER_TREE: {
            if (tool != nullptr) {
                memfree(tool);
                tool = nullptr;
            }

            #define WRAP_TOOL(m_type) \
                m_type *tmp_##m_type = Object::cast_to<m_type>(parent); \
                if (tmp_##m_type != nullptr) { \
                    tool = memnew(PathToolWrapper<m_type>(tmp_##m_type)); \
                    tool->register_modifier(this); \
                    break; \
                }

            Node *parent = get_parent();
            while (parent != nullptr) {
                WRAP_TOOL(PathMesh3D)
                WRAP_TOOL(PathExtrude3D)
                WRAP_TOOL(PathMultiMesh3D)
                WRAP_TOOL(PathScene3D)

                parent = parent->get_parent();
            }
        } break;

        case NOTIFICATION_EXIT_TREE: {
            if (tool != nullptr) {
                tool->unregister_modifier(this);
                memfree(tool);
                tool = nullptr;
            }
        }
    }
}

bool PathModifier3D::_property_can_revert(const StringName &p_name) const {
    return p_name == StringName("rotation_modifier") || p_name == StringName("rotation_randomness") || p_name == StringName("curve_offset_end");
}

bool PathModifier3D::_property_get_revert(const StringName &p_name, Variant &r_property) const {
    if (p_name == StringName("rotation_modifier") || p_name == StringName("rotation_randomness")) {
        switch (rotation_modifier_mode) {
            case ROTATION_EDIT_MODE_BASIS: {
                r_property = Basis();
                return true;
            } break;
            case ROTATION_EDIT_MODE_QUATERNION: {
                r_property = Quaternion();
                return true;
            } break;
            case ROTATION_EDIT_MODE_EULER: {
                r_property = Vector3();
                return true;
            } break;
            default:
                return false;
        }
    } else if (p_name == StringName("curve_offset_end")) {
        if (tool != nullptr) {
            const Ref<Curve3D> &path_curve = tool->get_curve_3d();
            if (path_curve.is_valid() && path_curve->get_baked_length() > 0.0) {
                r_property = path_curve->get_baked_length();
                return true;
            }
        }

        r_property = 0.0;
        return true;
    } else {
        return false;
    }
}

void PathModifier3D::_validate_property(PropertyInfo &p_property) const {
    if (p_property.name == StringName("rotation_modifier") || p_property.name == StringName("rotation_randomness")) {
        switch (rotation_modifier_mode) {
            case ROTATION_EDIT_MODE_BASIS: {
                p_property.type = Variant::BASIS;
            } break;
            case ROTATION_EDIT_MODE_QUATERNION: {
                p_property.type = Variant::QUATERNION;
            } break;
            case ROTATION_EDIT_MODE_EULER: {
                p_property.type = Variant::VECTOR3;
                p_property.hint = PROPERTY_HINT_RANGE;
                p_property.hint_string = "-180.0,180.0,0.001,radians_as_degrees";
            } break;
            default:
                p_property.type = Variant::NIL;
        }
    }
}

real_t PathModifier3D::_sample_influence(real_t p_offset_ratio) const {
    if (influence.is_valid()) {
        if (p_offset_ratio < curve_offset_ratio_start || p_offset_ratio > curve_offset_ratio_end) {
            return 0.0;
        } else {
            return influence->sample_baked(Math::remap(p_offset_ratio, real_t(0.0), real_t(1.0), curve_offset_ratio_start, curve_offset_ratio_end));
        }
    } else {
        return p_offset_ratio >= curve_offset_ratio_start && p_offset_ratio <= curve_offset_ratio_end ? 1.0 : 0.0;
    }
}


void PathModifier3D::_on_influence_changed() {
    queue_rebuild();
}