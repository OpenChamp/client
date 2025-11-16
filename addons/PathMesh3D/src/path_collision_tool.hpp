#pragma once

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/static_body3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/shape3d.hpp>
#include <godot_cpp/classes/concave_polygon_shape3d.hpp>
#include <godot_cpp/classes/convex_polygon_shape3d.hpp>
#include <godot_cpp/classes/mesh_convex_decomposition_settings.hpp>
#include <godot_cpp/templates/local_vector.hpp>

#define PATH_COLLISION_TOOL_HEADER(m_class, m_super, m_bake_name) \
    \
public: \
    enum Distribution { \
        DISTRIBUTE_BY_COUNT, \
        DISTRIBUTE_BY_DISTANCE, \
        DISTRIBUTE_MAX, \
    }; \
    enum Rotation { \
        ROTATE_FIXED, \
        ROTATE_PATH, \
        ROTATE_MAX, \
    }; \
    enum Alignment { \
        ALIGN_FROM_START, \
        ALIGN_CENTERED, \
        ALIGN_FROM_END, \
        ALIGN_MAX, \
    }; \
    \
    ~m_class(); \
    \
    void set_shape(const Ref<Shape3D> &p_shape); \
    Ref<Shape3D> get_shape() const; \
    \
    void set_distribution(Distribution p_distribution); \
    Distribution get_distribution() const; \
    \
    void set_alignment(Alignment p_alignment); \
    Alignment get_alignment() const; \
    \
    void set_count(uint64_t p_count); \
    uint64_t get_count() const; \
    \
    void set_distance(double p_distance); \
    double get_distance() const; \
    \
    void set_rotation_mode(Rotation p_rotation_mode); \
    Rotation get_rotation_mode() const; \
    \
    void set_rotation(const Vector3 &p_rotation); \
    Vector3 get_rotation() const; \
    \
    void set_sample_cubic(bool p_cubic); \
    bool get_sample_cubic() const; \
    \
    m_super *bake_##m_bake_name(); \
    \
protected: \
    static void _bind_methods(); \
    void _validate_property(PropertyInfo &p_property) const; \
    \
private: \
    Ref<Shape3D> shape; \
    Distribution distribution = DISTRIBUTE_BY_COUNT; \
    Alignment alignment = ALIGN_FROM_START; \
    uint64_t count = 1; \
    double distance = 1.0; \
    Rotation rotation_mode = ROTATE_FIXED; \
    Vector3 rotation = Vector3(); \
    bool sample_cubic = false; \
    \
    LocalVector<uint32_t> owners; \
    MultiMeshInstance3D *collision_debug = nullptr; \
    \
    void _on_shape_changed(); \


#define PATH_COLLISION_TOOL_IMPLEMENTATION(m_class, m_super, m_bake_name) \
using namespace godot; \
\
m_class::~m_class() { \
    PATH_TOOL_DESTRUCTOR(m_class) \
    \
    if (shape.is_valid()) { \
        if (shape->is_connected("changed", callable_mp(this, &m_class::_on_shape_changed))) { \
            shape->disconnect("changed", callable_mp(this, &m_class::_on_shape_changed)); \
        } \
        shape.unref(); \
    } \
} \
\
void m_class::set_shape(const Ref<Shape3D> &p_shape) { \
    if (shape != p_shape) { \
        if (shape.is_valid()) { \
            if (shape->is_connected("changed", callable_mp(this, &m_class::_on_shape_changed))) { \
                shape->disconnect("changed", callable_mp(this, &m_class::_on_shape_changed)); \
            } \
        } \
        \
        shape = p_shape; \
        \
        if (shape.is_valid()) { \
            shape->connect("changed", callable_mp(this, &m_class::_on_shape_changed)); \
        } \
        \
        _on_shape_changed(); \
    } \
} \
\
Ref<Shape3D> m_class::get_shape() const { \
    return shape; \
} \
\
void m_class::set_distribution(Distribution p_distribution) { \
    if (distribution != p_distribution) { \
        distribution = p_distribution; \
        queue_rebuild(); \
        notify_property_list_changed(); \
    } \
} \
\
auto m_class::get_distribution() const -> Distribution { \
    return distribution; \
} \
\
void m_class::set_alignment(Alignment p_alignment) { \
    if (alignment != p_alignment) { \
        alignment = p_alignment; \
        queue_rebuild(); \
    } \
} \
\
auto m_class::get_alignment() const -> Alignment{ \
    return alignment; \
} \
\
void m_class::set_count(uint64_t p_count) { \
    if (count != p_count) { \
        count = p_count; \
        queue_rebuild(); \
        if (distribution == DISTRIBUTE_BY_COUNT) { \
            queue_rebuild(); \
        } \
    } \
} \
\
uint64_t m_class::get_count() const { \
    return count; \
} \
\
void m_class::set_distance(double p_distance) { \
    if (distance != p_distance) { \
        distance = p_distance; \
        queue_rebuild(); \
        if (distribution == DISTRIBUTE_BY_DISTANCE) { \
            queue_rebuild(); \
        } \
    } \
} \
\
double m_class::get_distance() const { \
    return distance; \
} \
\
void m_class::set_rotation_mode(Rotation p_rotation_mode) { \
    if (rotation_mode != p_rotation_mode) { \
        rotation_mode = p_rotation_mode; \
        queue_rebuild(); \
    } \
} \
\
auto m_class::get_rotation_mode() const -> Rotation { \
    return rotation_mode; \
} \
\
void m_class::set_rotation(const Vector3 &p_rotation) { \
    if (rotation != p_rotation) { \
        rotation = p_rotation; \
        queue_rebuild(); \
    } \
} \
\
Vector3 m_class::get_rotation() const { \
    return rotation; \
} \
\
void m_class::set_sample_cubic(bool p_cubic) { \
    if (sample_cubic != p_cubic) { \
        sample_cubic = p_cubic; \
        queue_rebuild(); \
    } \
} \
\
bool m_class::get_sample_cubic() const { \
    return sample_cubic; \
} \
\
m_super *m_class::bake_##m_bake_name() { \
    m_super *out = memnew(m_super); \
    Ref<Shape3D> new_shape = shape->duplicate(); \
    \
    for (const uint32_t owner_id : owners) { \
        CollisionShape3D *new_obj = memnew(CollisionShape3D); \
        new_obj->set_shape(new_shape); \
        out->add_child(new_obj); \
        new_obj->set_transform(shape_owner_get_transform(owner_id)); \
        if (out->get_owner() != nullptr) { \
            new_obj->set_owner(out->get_owner()); \
        } \
    } \
    \
    return out; \
} \
\
void m_class::_bind_methods() { \
    PATH_TOOL_BINDS(m_class, shape, SHAPE) \
    \
    ClassDB::bind_method(D_METHOD("bake_" #m_bake_name), &m_class::bake_##m_bake_name); \
    \
    ClassDB::bind_method(D_METHOD("set_shape", "shape"), &m_class::set_shape); \
    ClassDB::bind_method(D_METHOD("get_shape"), &m_class::get_shape); \
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "shape", PROPERTY_HINT_RESOURCE_TYPE, "Shape3D"), "set_shape", "get_shape"); \
    \
    ClassDB::bind_method(D_METHOD("set_distribution", "distribution"), &m_class::set_distribution); \
    ClassDB::bind_method(D_METHOD("get_distribution"), &m_class::get_distribution); \
    ADD_PROPERTY(PropertyInfo(Variant::INT, "distribution", PROPERTY_HINT_ENUM, "By Count,By Distance"), "set_distribution", "get_distribution"); \
    \
    ClassDB::bind_method(D_METHOD("set_alignment", "alignment"), &m_class::set_alignment); \
    ClassDB::bind_method(D_METHOD("get_alignment"), &m_class::get_alignment); \
    ADD_PROPERTY(PropertyInfo(Variant::INT, "alignment", PROPERTY_HINT_ENUM, "From Start,Centered,From End"), "set_alignment", "get_alignment"); \
    \
    ClassDB::bind_method(D_METHOD("set_count", "count"), &m_class::set_count); \
    ClassDB::bind_method(D_METHOD("get_count"), &m_class::get_count); \
    ADD_PROPERTY(PropertyInfo(Variant::INT, "count", PROPERTY_HINT_RANGE, "0,1000,1,or_greater"), "set_count", "get_count"); \
    \
    ClassDB::bind_method(D_METHOD("set_distance", "distance"), &m_class::set_distance); \
    ClassDB::bind_method(D_METHOD("get_distance"), &m_class::get_distance); \
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "distance", PROPERTY_HINT_RANGE, "0.01,1000.0,0.01,or_greater"), "set_distance", "get_distance"); \
    \
    ClassDB::bind_method(D_METHOD("set_rotation_mode", "rotation_mode"), &m_class::set_rotation_mode); \
    ClassDB::bind_method(D_METHOD("get_rotation_mode"), &m_class::get_rotation_mode); \
    ADD_PROPERTY(PropertyInfo(Variant::INT, "rotation_mode", PROPERTY_HINT_ENUM, "Fixed,Path"), "set_rotation_mode", "get_rotation_mode"); \
    \
    ClassDB::bind_method(D_METHOD("set_rotation", "rotation"), &m_class::set_rotation); \
    ClassDB::bind_method(D_METHOD("get_rotation"), &m_class::get_rotation); \
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "rotation"), "set_rotation", "get_rotation"); \
    \
    ClassDB::bind_method(D_METHOD("set_sample_cubic", "cubic"), &m_class::set_sample_cubic); \
    ClassDB::bind_method(D_METHOD("get_sample_cubic"), &m_class::get_sample_cubic); \
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "sample_cubic"), "set_sample_cubic", "get_sample_cubic"); \
    \
    ADD_SIGNAL(MethodInfo("shape_changed")); \
    \
    BIND_ENUM_CONSTANT(DISTRIBUTE_BY_COUNT); \
    BIND_ENUM_CONSTANT(DISTRIBUTE_BY_DISTANCE); \
    BIND_ENUM_CONSTANT(ALIGN_FROM_START); \
    BIND_ENUM_CONSTANT(ALIGN_CENTERED); \
    BIND_ENUM_CONSTANT(ALIGN_FROM_END); \
    BIND_ENUM_CONSTANT(ROTATE_FIXED); \
    BIND_ENUM_CONSTANT(ROTATE_PATH); \
} \
\
void m_class::_notification(int p_what) { \
    switch (p_what) { \
        case NOTIFICATION_READY: { \
            set_process_internal(true); \
            _rebuild_mesh(); \
        } break; \
        \
        case NOTIFICATION_INTERNAL_PROCESS: { \
            if (_pop_is_dirty()) { \
                _rebuild_mesh(); \
            } \
        } break; \
    } \
} \
\
void m_class::_validate_property(PropertyInfo &p_property) const { \
    if (p_property.name == StringName("count") && distribution == DISTRIBUTE_BY_DISTANCE) { \
        p_property.usage = PROPERTY_USAGE_NONE; \
    } else if (p_property.name == StringName("distance") && distribution == DISTRIBUTE_BY_COUNT) { \
        p_property.usage = PROPERTY_USAGE_NONE; \
    } \
} \
\
void m_class::_rebuild_mesh() { \
    for (const uint32_t owner_id : owners) { \
        shape_owner_clear_shapes(owner_id); \
        remove_shape_owner(owner_id); \
    } \
    owners.clear(); \
    \
    if (collision_debug != nullptr) { \
        remove_child(collision_debug); \
        collision_debug->queue_free(); \
        collision_debug = nullptr; \
    } \
    \
    if (path3d == nullptr || path3d->get_curve().is_null() || !path3d->is_inside_tree() || !shape.is_valid()) { \
        return; \
    } \
    \
    Transform3D mod_transform = _get_relative_transform(); \
    \
    Ref<Curve3D> curve = path3d->get_curve(); \
    if (curve->get_point_count() < 2) { \
        return; \
    } \
    \
    double baked_l = curve->get_baked_length(); \
    if (baked_l == 0.0) { \
        return; \
    } \
    \
    uint64_t n_instances = 0; \
    double separation = 0.0; \
    switch (distribution) { \
        case DISTRIBUTE_BY_COUNT: { \
            n_instances = count; \
            separation = baked_l / (count - 1); \
        } break; \
        case DISTRIBUTE_BY_DISTANCE: { \
            separation = distance; \
            n_instances = Math::floor(baked_l / separation) + 1; \
        } break; \
        default: \
            ERR_FAIL(); \
    } \
    \
    double offset = 0.0; \
    if (distribution != DISTRIBUTE_BY_COUNT) { \
        switch (alignment) { \
            case ALIGN_FROM_START: { \
                offset = 0.0; \
            } break; \
            case ALIGN_CENTERED: { \
                offset = (baked_l - separation * (n_instances - 1)) * 0.5; \
            } break; \
            case ALIGN_FROM_END: { \
                offset = baked_l - separation * (n_instances - 1); \
            } break; \
            default: \
                ERR_FAIL(); \
        } \
    } \
    \
    bool debugging = Engine::get_singleton()->is_editor_hint() || get_tree()->is_debugging_collisions_hint(); \
    \
    if (debugging) { \
        collision_debug = memnew(MultiMeshInstance3D); \
        collision_debug->set_multimesh(memnew(MultiMesh)); \
        collision_debug->get_multimesh()->set_transform_format(MultiMesh::TRANSFORM_3D); \
        collision_debug->get_multimesh()->set_instance_count(n_instances); \
        collision_debug->get_multimesh()->set_mesh(shape->get_debug_mesh()); \
        add_child(collision_debug, false, INTERNAL_MODE_BACK); \
    } \
    \
    owners.resize(n_instances); \
    for (uint64_t i = 0; i < n_instances; ++i) { \
        Transform3D transform; \
        switch (rotation_mode) { \
            case ROTATE_FIXED: { \
                transform.origin = curve->sample_baked(offset, sample_cubic); \
                transform.basis = Basis::from_euler(rotation); \
            } break; \
            case ROTATE_PATH: { \
                transform = curve->sample_baked_with_rotation(offset, sample_cubic, true); \
                transform.basis.rotate(rotation); \
            } break; \
            default: \
                ERR_FAIL(); \
        } \
        \
        transform *= _sample_3d_modifiers_at(offset / baked_l); \
        \
        if (relative_transform == TRANSFORM_SHAPE_PATH_NODE) { \
            transform = mod_transform * transform; \
        } \
        \
        if (debugging) { \
            collision_debug->get_multimesh()->set_instance_transform(i, transform); \
        } \
        \
        uint32_t owner_id = create_shape_owner(this); \
        shape_owner_add_shape(owner_id, shape); \
        shape_owner_set_transform(owner_id, transform); \
        owners[i] = owner_id; \
        offset += separation; \
    } \
} \
\
void m_class::_on_shape_changed() { \
    queue_rebuild(); \
    emit_signal("shape_changed"); \
}


#define PATH_MESH_WITH_COLLISION(m_generated_mesh) \
public: \
    enum CollisionMode { \
        COLLISION_MODE_NONE = 0, \
        COLLISION_MODE_TRIMESH, \
        COLLISION_MODE_CONVEX, \
        COLLISION_MODE_MULTIPLE_CONVEX, \
    }; \
    \
    _FORCE_INLINE_ void set_generate_collision(const CollisionMode p_mode) { \
        if (collision_mode != p_mode) { \
            collision_mode = p_mode; \
            queue_rebuild_collision(); \
            notify_property_list_changed(); \
        } \
    } \
    \
    _FORCE_INLINE_ CollisionMode get_generate_collision() const { return collision_mode; } \
    \
    _FORCE_INLINE_ void set_convex_collision_clean(bool p_clean) { \
        if (convex_collision_clean != p_clean) { \
            convex_collision_clean = p_clean; \
            queue_rebuild_collision(); \
        } \
    } \
    \
    _FORCE_INLINE_ bool get_convex_collision_clean() const { return convex_collision_clean; } \
    \
    _FORCE_INLINE_ void set_convex_collision_simplify(bool p_simplify) { \
        if (convex_collision_simplify != p_simplify) { \
            convex_collision_simplify = p_simplify; \
            queue_rebuild_collision(); \
        } \
    } \
    \
    _FORCE_INLINE_ bool get_convex_collision_simplify() const { return convex_collision_simplify; } \
    \
    _FORCE_INLINE_ Node *get_collision_node() const { return collision_node; } \
    \
    _FORCE_INLINE_ void queue_rebuild_collision() { collision_dirty = true; } \
    \
    _FORCE_INLINE_ Node *create_trimesh_collision_node() { \
        return _setup_collision_node(m_generated_mesh->create_trimesh_shape()); \
    } \
    \
    _FORCE_INLINE_ void create_trimesh_collision() { \
        _add_child_collision_node(create_trimesh_collision_node()); \
    } \
    \
    _FORCE_INLINE_ Node *create_convex_collision_node(bool p_clean = true, bool p_simplify = false) { \
        return _setup_collision_node(m_generated_mesh->create_convex_shape(p_clean, p_simplify)); \
    } \
    \
    _FORCE_INLINE_ void create_convex_collision(bool p_clean = true, bool p_simplify = false) { \
        _add_child_collision_node(create_convex_collision_node(p_clean, p_simplify)); \
    } \
    \
    _FORCE_INLINE_ Node *create_multiple_convex_collision_node(const Ref<MeshConvexDecompositionSettings> &p_settings = nullptr) { \
        Ref<MeshConvexDecompositionSettings> settings = p_settings; \
        if (!settings.is_valid()) { \
            settings.instantiate(); \
        } \
        \
        /* TODO: GDExtension doesn't have API parity here... */ \
        LocalVector<Ref<Shape3D>> shapes; /* = m_generated_mesh->convex_decompose(settings); */ \
        if (shapes.is_empty()) { \
            return nullptr; \
        } \
        \
        StaticBody3D *static_body = memnew(StaticBody3D); \
        for (int i = 0; i < shapes.size(); ++i) { \
            CollisionShape3D *cshape = memnew(CollisionShape3D); \
            cshape->set_shape(shapes[i]); \
            static_body->add_child(cshape, true); \
        } \
        return static_body; \
    } \
    \
    _FORCE_INLINE_ void create_multiple_convex_collision(const Ref<MeshConvexDecompositionSettings> &p_settings = nullptr) { \
        _add_child_collision_node(create_multiple_convex_collision_node(p_settings)); \
    } \
    \
protected: \
    void _validate_property(PropertyInfo &p_property) const { \
        if (p_property.name == StringName("convex_collision_clean") || p_property.name == StringName("convex_collision_simplify")) { \
            p_property.usage = collision_mode == COLLISION_MODE_CONVEX ? PROPERTY_USAGE_DEFAULT : PROPERTY_USAGE_NONE; \
        } \
    } \
    \
private: \
    CollisionMode collision_mode = COLLISION_MODE_NONE; \
    bool convex_collision_clean = true; \
    bool convex_collision_simplify = false; \
    bool collision_dirty = false; \
    Node *collision_node = nullptr; \
    MeshInstance3D *collision_debug = nullptr; \
    \
    _FORCE_INLINE_ Node *_setup_collision_node(const Ref<Shape3D> &shape) { \
        StaticBody3D *static_body = memnew(StaticBody3D); \
        CollisionShape3D *cshape = memnew(CollisionShape3D); \
        cshape->set_shape(shape); \
        static_body->add_child(cshape, true); \
        return static_body; \
    } \
    \
    _FORCE_INLINE_ void _add_child_collision_node(Node *p_node) { \
        if (p_node != nullptr) { \
            add_child(p_node, true); \
            if (get_owner() != nullptr) { \
                p_node->set_owner(get_owner()); \
                for (int i = 0; i < p_node->get_child_count(); ++i) { \
                    Node *c = p_node->get_child(i); \
                    c->set_owner(get_owner()); \
                } \
            } \
        } \
    } \
    \
    _FORCE_INLINE_ void _rebuild_collision_node() { \
        collision_dirty = false; \
        \
        if (collision_node != nullptr) { \
            remove_child(collision_node); \
            collision_node->queue_free(); \
            collision_node = nullptr; \
        } \
        \
        if (collision_debug != nullptr) { \
            remove_child(collision_debug); \
            collision_debug->queue_free(); \
            collision_debug = nullptr; \
        } \
        \
        switch (collision_mode) { \
            case COLLISION_MODE_TRIMESH: \
                collision_node = create_trimesh_collision_node(); \
                break; \
            case COLLISION_MODE_CONVEX: \
                collision_node = create_convex_collision_node(convex_collision_clean, convex_collision_simplify); \
                break; \
            case COLLISION_MODE_MULTIPLE_CONVEX: \
                collision_node = create_multiple_convex_collision_node(); \
                break; \
            default: \
                break; \
        } \
        \
        if (collision_node != nullptr) { \
            add_child(collision_node, false, INTERNAL_MODE_BACK); \
            \
            if (Engine::get_singleton()->is_editor_hint() || get_tree()->is_debugging_collisions_hint()) { \
                collision_debug = memnew(MeshInstance3D); \
                collision_debug->set_mesh(cast_to<CollisionShape3D>(collision_node->get_child(0))->get_shape()->get_debug_mesh()); \
                add_child(collision_debug, false, INTERNAL_MODE_BACK); \
            } \
        } \
    }
    

#define PATH_MESH_WITH_COLLISION_BINDS(m_class) \
    ADD_GROUP("Collision", ""); \
    ClassDB::bind_method(D_METHOD("set_generate_collision", "mode"), &m_class::set_generate_collision); \
    ClassDB::bind_method(D_METHOD("get_generate_collision"), &m_class::get_generate_collision); \
    ADD_PROPERTY(PropertyInfo(Variant::INT, "collision_mode", PROPERTY_HINT_ENUM, "None,Trimesh,Convex,Multiple Convex"), "set_generate_collision", "get_generate_collision"); \
    \
    ClassDB::bind_method(D_METHOD("set_convex_collision_clean", "clean"), &m_class::set_convex_collision_clean); \
    ClassDB::bind_method(D_METHOD("get_convex_collision_clean"), &m_class::get_convex_collision_clean); \
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "convex_collision_clean"), "set_convex_collision_clean", "get_convex_collision_clean"); \
    \
    ClassDB::bind_method(D_METHOD("set_convex_collision_simplify", "simplify"), &m_class::set_convex_collision_simplify); \
    ClassDB::bind_method(D_METHOD("get_convex_collision_simplify"), &m_class::get_convex_collision_simplify); \
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "convex_collision_simplify"), "set_convex_collision_simplify", "get_convex_collision_simplify"); \
    \
    ClassDB::bind_method(D_METHOD("create_trimesh_collision"), &m_class::create_trimesh_collision); \
    ClassDB::bind_method(D_METHOD("create_convex_collision", "clean", "simplify"), &m_class::create_convex_collision, DEFVAL(true), DEFVAL(false)); \
    ClassDB::bind_method(D_METHOD("create_multiple_convex_collision", "settings"), &m_class::create_multiple_convex_collision, DEFVAL(nullptr)); \
    \
    BIND_ENUM_CONSTANT(COLLISION_MODE_NONE); \
    BIND_ENUM_CONSTANT(COLLISION_MODE_TRIMESH); \
    BIND_ENUM_CONSTANT(COLLISION_MODE_CONVEX); \
    BIND_ENUM_CONSTANT(COLLISION_MODE_MULTIPLE_CONVEX);
    