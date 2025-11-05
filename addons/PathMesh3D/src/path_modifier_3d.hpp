#pragma once

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/curve.hpp>

namespace godot {

class PathToolInterface;

class PathModifier3D : public Node3D {
    GDCLASS(PathModifier3D, Node3D)

public:
    void set_curve_offset_start(real_t p_offset);
    real_t get_curve_offset_start() const;

    void set_curve_offset_end(real_t p_offset);
    real_t get_curve_offset_end() const;

    void set_curve_offset_ratio_start(real_t p_offset_ratio);
    real_t get_curve_offset_ratio_start() const;

    void set_curve_offset_ratio_end(real_t p_offset_ratio);
    real_t get_curve_offset_ratio_end() const;

    void set_influence(const Ref<Curve> &p_curve);
    Ref<Curve> get_influence() const;

    void set_position_modifier(Vector3 p_modifier);
    Vector3 get_position_modifier() const;

    void set_position_randomness(Vector3 p_randomness);
    Vector3 get_position_randomness() const;

    void set_rotation_modifier_mode(RotationEditMode p_mode);
    RotationEditMode get_rotation_modifier_mode() const;

    void set_rotation_modifier(const Variant &p_modifier);
    Variant get_rotation_modifier() const;

    void set_rotation_randomness(const Variant &p_randomness);
    Variant get_rotation_randomness() const;

    template<typename T> inline void set_rotation_modifier_t(T p_modifier);
    template<typename T> inline T get_rotation_modifier_t() const;

    template<typename T> inline void set_rotation_randomness_t(T p_randomness);
    template<typename T> inline T get_rotation_randomness_t() const;

    void set_scale_modifier(Vector3 p_modifier);
    Vector3 get_scale_modifier() const;

    void set_scale_randomness(Vector3 p_randomness);
    Vector3 get_scale_randomness() const;

    void set_uv_offset_modifier(Vector2 p_modifier);
    Vector2 get_uv_offset_modifier() const;

    void set_uv_offset_randomness(Vector2 p_randomness);
    Vector2 get_uv_offset_randomness() const;

    void set_uv_scale_modifier(Vector2 p_modifier);
    Vector2 get_uv_scale_modifier() const;

    void set_uv_scale_randomness(Vector2 p_randomness);
    Vector2 get_uv_scale_randomness() const;

    Transform3D sample_3d_modifier_at(real_t p_offset_ratio) const;
    Transform2D sample_uv_modifier_at(real_t p_offset_ratio) const;

    void queue_rebuild();

    bool pop_is_dirty();

protected:
    static void _bind_methods();
    void _notification(int p_what);
    void _validate_property(PropertyInfo &p_property) const;
    bool _property_can_revert(const StringName &p_name) const;
    bool _property_get_revert(const StringName &p_name, Variant &r_property) const;

private:
    real_t curve_offset_ratio_start = 0.0;
    real_t curve_offset_ratio_end = 1.0;

    Ref<Curve> influence;
    
    Vector3 position_modifier = { 0.0, 0.0, 0.0 };
    Vector3 position_randomness = { 0.0, 0.0, 0.0 };
    RotationEditMode rotation_modifier_mode = ROTATION_EDIT_MODE_EULER;
    Quaternion rotation_modifier;
    Quaternion rotation_randomness;
    Vector3 scale_modifier = { 1.0, 1.0, 1.0 };
    Vector3 scale_randomness = { 0.0, 0.0, 0.0 };
    Vector2 uv_offset_modifier = { 0.0, 0.0 };
    Vector2 uv_offset_randomness = { 0.0, 0.0 };
    Vector2 uv_scale_modifier = { 1.0, 1.0 };
    Vector2 uv_scale_randomness = { 0.0, 0.0 };

    bool dirty = true;

    PathToolInterface *tool = nullptr;
    
    real_t _sample_influence(real_t p_offset_ratio) const;
    void _on_influence_changed();
};

template<> inline void PathModifier3D::set_rotation_modifier_t<Quaternion>(Quaternion p_modifier) {
    if (p_modifier != rotation_modifier) {
        rotation_modifier = p_modifier;
        queue_rebuild();
    }
}

template<> inline void PathModifier3D::set_rotation_modifier_t<Basis>(Basis p_modifier) {
    set_rotation_modifier_t<Quaternion>(p_modifier.get_rotation_quaternion());
}

template<> inline void PathModifier3D::set_rotation_modifier_t<Vector3>(Vector3 p_modifier) {
    set_rotation_modifier_t<Quaternion>(Quaternion::from_euler(p_modifier));
}

template<> inline Basis PathModifier3D::get_rotation_modifier_t<Basis>() const {
    return Basis(rotation_modifier);
}

template<> inline Quaternion PathModifier3D::get_rotation_modifier_t<Quaternion>() const {
    return rotation_modifier;
}

template<> inline Vector3 PathModifier3D::get_rotation_modifier_t<Vector3>() const {
    return rotation_modifier.get_euler();
}

template<> inline void PathModifier3D::set_rotation_randomness_t<Quaternion>(Quaternion p_randomness) {
    if (p_randomness != rotation_randomness) {
        rotation_randomness = p_randomness;
        queue_rebuild();
    }
}

template<> inline void PathModifier3D::set_rotation_randomness_t<Basis>(Basis p_randomness) {
    set_rotation_randomness_t<Quaternion>(p_randomness.get_rotation_quaternion());
}

template<> inline void PathModifier3D::set_rotation_randomness_t<Vector3>(Vector3 p_randomness) {
    set_rotation_randomness_t<Quaternion>(Quaternion::from_euler(p_randomness));
}

template<> inline Basis PathModifier3D::get_rotation_randomness_t<Basis>() const {
    return Basis(rotation_randomness);
}

template<> inline Quaternion PathModifier3D::get_rotation_randomness_t<Quaternion>() const {
    return rotation_randomness;
}

template<> inline Vector3 PathModifier3D::get_rotation_randomness_t<Vector3>() const {
    return rotation_randomness.get_euler();
}

}