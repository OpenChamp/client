#pragma once

#include <godot_cpp/classes/path3d.hpp>
#include <godot_cpp/templates/local_vector.hpp>

#include "path_modifier_3d.hpp"

#define PATH_TOOL(m_class, m_type) \
public: \
    enum RelativeTransform { \
        TRANSFORM_##m_type##_LOCAL, \
        TRANSFORM_##m_type##_PATH_NODE, \
        TRANSFOMR_##m_type##_MAX, \
    }; \
    \
    _FORCE_INLINE_ void set_path_3d(Path3D *p_path) { \
        if (p_path != path3d) { \
            if (path3d != nullptr && path3d->is_connected("curve_changed", callable_mp(this, &m_class::_on_curve_changed))) { \
                path3d->disconnect("curve_changed", callable_mp(this, &m_class::_on_curve_changed)); \
            } \
    \
            path3d = p_path; \
    \
            if (path3d != nullptr && !path3d->is_connected("curve_changed", callable_mp(this, &m_class::_on_curve_changed))) { \
                path3d->connect("curve_changed", callable_mp(this, &m_class::_on_curve_changed)); \
            } \
    \
            _on_curve_changed(); \
        } \
    } \
    \
    _FORCE_INLINE_ Path3D *get_path_3d() const { return path3d; } \
    \
    _FORCE_INLINE_ void set_relative_transform(const RelativeTransform p_transform) { \
        if (relative_transform != p_transform) { \
            relative_transform = p_transform; \
            queue_rebuild(); \
        } \
    } \
    \
    _FORCE_INLINE_ RelativeTransform get_relative_transform() const { return relative_transform; } \
    \
    _FORCE_INLINE_ void register_modifier(PathModifier3D *p_modifier) { \
        if (!modifiers.has(p_modifier)) { \
            modifiers.push_back(p_modifier); \
            queue_rebuild(); \
        } \
    } \
    \
    _FORCE_INLINE_ void unregister_modifier(PathModifier3D *p_modifier) { \
        if (modifiers.has(p_modifier)) { \
            modifiers.erase(p_modifier); \
            queue_rebuild(); \
        } \
    } \
    \
    _FORCE_INLINE_ void queue_rebuild() { dirty = true; } \
    \
protected: \
    void _notification(int p_what); \
    \
private: \
    Path3D *path3d = nullptr; \
    RelativeTransform relative_transform = TRANSFORM_##m_type##_LOCAL; \
    Transform3D self_transform; \
    Transform3D path_transform; \
    LocalVector<PathModifier3D *> modifiers; \
    bool dirty = true; \
    \
    _FORCE_INLINE_ bool _pop_is_dirty() { \
        bool is_dirty = dirty; \
        if (!is_dirty && relative_transform == TRANSFORM_##m_type##_PATH_NODE) { \
            Transform3D tmp = get_global_transform(); \
            is_dirty = is_dirty || self_transform != tmp; \
            self_transform = tmp; \
            if (path3d != nullptr) { \
                tmp = path3d->get_global_transform(); \
                is_dirty = is_dirty || path_transform != tmp; \
                path_transform = tmp; \
            } \
        } \
    \
        for (PathModifier3D *modifier : modifiers) { \
            is_dirty = is_dirty || modifier->pop_is_dirty(); \
        } \
    \
        dirty = false; \
        return is_dirty; \
    } \
    \
    _FORCE_INLINE_ Transform3D _get_relative_transform() const { \
        return self_transform.affine_inverse() * path_transform; \
    } \
    \
    _FORCE_INLINE_ Transform3D _sample_3d_modifiers_at(real_t p_offset_ratio) const { \
        Transform3D out; \
        for (PathModifier3D *modifier : modifiers) { \
            out *= modifier->sample_3d_modifier_at(p_offset_ratio); \
        } \
        return out; \
    }\
    \
    _FORCE_INLINE_ Transform2D _sample_uv_modifiers_at(real_t p_offset_ratio) const { \
        Transform2D out; \
        for (PathModifier3D *modifier : modifiers) { \
            out *= modifier->sample_uv_modifier_at(p_offset_ratio); \
        } \
        return out; \
    } \
    \
    void _rebuild_mesh(); \
    \
    _FORCE_INLINE_ void _on_curve_changed() { \
        queue_rebuild(); \
        emit_signal("curve_changed"); \
    }

#define PATH_TOOL_BINDS(m_class, m_type_lower, m_type_upper) \
    ClassDB::bind_method(D_METHOD("queue_rebuild"), &m_class::queue_rebuild); \
    \
    ClassDB::bind_method(D_METHOD("set_path_3d", "path"), &m_class::set_path_3d); \
    ClassDB::bind_method(D_METHOD("get_path_3d"), &m_class::get_path_3d); \
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "path_3d", PROPERTY_HINT_NODE_TYPE, "Path3D"), "set_path_3d", "get_path_3d"); \
    \
    ClassDB::bind_method(D_METHOD("set_" #m_type_lower "_transform", "transform"), &m_class::set_relative_transform); \
    ClassDB::bind_method(D_METHOD("get_" #m_type_lower "_transform"), &m_class::get_relative_transform); \
    ADD_PROPERTY(PropertyInfo(Variant::INT, #m_type_lower "_transform", PROPERTY_HINT_ENUM, "Transform to Self,Transform to Path Node"), "set_" #m_type_lower "_transform", "get_" #m_type_lower "_transform"); \
    \
    ADD_SIGNAL(MethodInfo("curve_changed")); \
    \
    BIND_ENUM_CONSTANT(TRANSFORM_##m_type_upper##_LOCAL); \
    BIND_ENUM_CONSTANT(TRANSFORM_##m_type_upper##_PATH_NODE);

#define PATH_TOOL_DESTRUCTOR(m_class) \
    if (path3d != nullptr) { \
        if (UtilityFunctions::is_instance_id_valid(path3d->get_instance_id()) && \
            path3d->is_connected("curve_changed", callable_mp(this, &m_class::_on_curve_changed))) { \
        path3d->disconnect("curve_changed", callable_mp(this, &m_class::_on_curve_changed)); \
        } \
    } \
    path3d = nullptr;



namespace godot {

 /* HELPER CLASSES */
class PathToolInterface {
public:
    virtual Path3D *get_path_3d() const = 0;
    virtual Ref<Curve3D> get_curve_3d() const = 0;

    virtual void register_modifier(PathModifier3D *p_modifier) = 0;
    virtual void unregister_modifier(PathModifier3D *p_modifier) = 0;
};

template<typename T>
class PathToolWrapper : public PathToolInterface {

public:
    PathToolWrapper(T* p_tool) : tool(p_tool) {}
    ~PathToolWrapper() {
        tool = nullptr;
    }

    Path3D *get_path_3d() const override {
        if (tool != nullptr) {
            return tool->get_path_3d();
        } else {
            return nullptr;
        }
    }

    Ref<Curve3D> get_curve_3d() const override {
        Path3D *path3d = get_path_3d();
        if (path3d != nullptr) {
            return path3d->get_curve();
        } else {
            return nullptr;
        }
    }

    void register_modifier(PathModifier3D *p_modifier) override {
        if (tool != nullptr) {
            tool->register_modifier(p_modifier);
        }
    }

    void unregister_modifier(PathModifier3D *p_modifier) override {
        if (tool != nullptr) {
            tool->unregister_modifier(p_modifier);
        }
    }

private:
    T* tool = nullptr;
};

}