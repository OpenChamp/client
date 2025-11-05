#include "path_extrude_profile_circle.hpp"

#include <godot_cpp/classes/mesh.hpp>

using namespace godot;

void PathExtrudeProfileCircle::set_radius(const double p_radius) {
    if (p_radius != radius) {
        radius = p_radius;
        queue_update();
    }
}

double PathExtrudeProfileCircle::get_radius() const { 
    return radius; 
}

void PathExtrudeProfileCircle::set_starting_angle(const double p_starting_angle) {
    if (p_starting_angle != starting_angle) { 
        starting_angle = Math::clamp(p_starting_angle, double(0.0), double(Math_TAU)); 
        if (starting_angle > ending_angle) {
            ending_angle = starting_angle;
        }
        queue_update(); 
    } 
}

double PathExtrudeProfileCircle::get_starting_angle() const { 
    return starting_angle; 
}

void PathExtrudeProfileCircle::set_ending_angle(const double p_ending_angle) { 
    if (p_ending_angle != ending_angle) { 
        ending_angle = Math::clamp(p_ending_angle, double(0.0), double(Math_TAU)); 
        if (ending_angle < starting_angle) {
            starting_angle = ending_angle;
        }
        queue_update(); 
    } 
}

double PathExtrudeProfileCircle::get_ending_angle() const { 
    return ending_angle; 
}

void PathExtrudeProfileCircle::set_smooth_normals(const bool p_smooth_normals) { 
    if (p_smooth_normals != smooth_normals) { 
        smooth_normals = p_smooth_normals; 
        queue_update(); 
    } 
}

bool PathExtrudeProfileCircle::get_smooth_normals() const { 
    return smooth_normals; 
}

void PathExtrudeProfileCircle::set_closed(const bool p_closed) { 
    if (p_closed != closed) { 
        closed = p_closed; 
        queue_update(); 
    } 
}

bool PathExtrudeProfileCircle::is_closed() const { 
    return closed; 
}

void PathExtrudeProfileCircle::set_segments(const uint64_t p_segments) { 
    if (p_segments != segments && p_segments > 1) { 
        segments = p_segments; 
        queue_update(); 
    } 
}

uint64_t PathExtrudeProfileCircle::get_segments() const { 
    return segments; 
}

Array PathExtrudeProfileCircle::_generate_cross_section() {
    PackedVector2Array cs;
    PackedVector2Array norms;

    double swept_angle = ending_angle - starting_angle;
    if (swept_angle <= 0.0) {
        return Array::make(PackedVector2Array());
    }

    double da = swept_angle / double(segments);

    if (smooth_normals) {
        cs.resize(segments + 1);
        norms.resize(segments + 1);
        for (uint64_t i = 0; i <= segments; ++i) {
            double ang = ending_angle - da * i;
            norms[i] = Vector2(Math::sin(ang), Math::cos(ang));
            cs[i] = norms[i] * radius;
        }
    } else {
        cs.resize(segments * 2);
        norms.resize(segments * 2);
        for (uint64_t i = 0; i < segments; ++i) {
            double ang = ending_angle - da * i;
            Vector2 start_segment = Vector2(Math::sin(ang), Math::cos(ang));
            Vector2 end_segment = Vector2(Math::sin(ang - da), Math::cos(ang - da));
            Vector2 segment = end_segment - start_segment;
            Vector2 segment_normal = Vector2(segment.y, -segment.x).normalized();

            cs[i * 2] = start_segment * radius;
            cs[i * 2 + 1] = end_segment * radius;
            norms[i * 2] = segment_normal;
            norms[i * 2 + 1] = segment_normal;
        }
    }

    if (closed && cs[0].distance_squared_to(cs[cs.size() - 1]) > 1.0e-6) {
        Vector2 end_segment_start = cs[cs.size() - 1];
        Vector2 end_segment_end = cs[0];
        Vector2 end_segment = end_segment_end - end_segment_start;
        Vector2 end_segment_normal = Vector2(end_segment.y, -end_segment.x).normalized();
        cs.push_back(end_segment_start);
        cs.push_back(end_segment_end);
        norms.push_back(end_segment_normal);
        norms.push_back(end_segment_normal);
    }

    Array out;
    out.resize(Mesh::ARRAY_MAX);
    out[Mesh::ARRAY_VERTEX] = cs;
    out[Mesh::ARRAY_NORMAL] = norms;
    out[Mesh::ARRAY_TEX_UV] = _generate_v(cs);;
    return out;
}

void PathExtrudeProfileCircle::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_radius", "radius"), &PathExtrudeProfileCircle::set_radius);
    ClassDB::bind_method(D_METHOD("get_radius"), &PathExtrudeProfileCircle::get_radius);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "radius", PROPERTY_HINT_RANGE, "0.0,100.0,0.01,or_greater"), "set_radius", "get_radius");

    ClassDB::bind_method(D_METHOD("set_starting_angle", "starting_angle"), &PathExtrudeProfileCircle::set_starting_angle);
    ClassDB::bind_method(D_METHOD("get_starting_angle"), &PathExtrudeProfileCircle::get_starting_angle);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "starting_angle", PROPERTY_HINT_RANGE, "0.0,360.0,0.01,radians_as_degrees"), "set_starting_angle", "get_starting_angle");

    ClassDB::bind_method(D_METHOD("set_ending_angle", "ending_angle"), &PathExtrudeProfileCircle::set_ending_angle);
    ClassDB::bind_method(D_METHOD("get_ending_angle"), &PathExtrudeProfileCircle::get_ending_angle);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "ending_angle", PROPERTY_HINT_RANGE, "0.0,360.0,0.01,radians_as_degrees"), "set_ending_angle", "get_ending_angle");

    ClassDB::bind_method(D_METHOD("set_closed", "closed"), &PathExtrudeProfileCircle::set_closed);
    ClassDB::bind_method(D_METHOD("get_closed"), &PathExtrudeProfileCircle::is_closed);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "closed"), "set_closed", "get_closed");

    ClassDB::bind_method(D_METHOD("set_segments", "segments"), &PathExtrudeProfileCircle::set_segments);
    ClassDB::bind_method(D_METHOD("get_segments"), &PathExtrudeProfileCircle::get_segments);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "segments", PROPERTY_HINT_RANGE, "0,256,1,or_greater"), "set_segments", "get_segments");

    ClassDB::bind_method(D_METHOD("set_smooth_normals", "smooth_normals"), &PathExtrudeProfileCircle::set_smooth_normals);
    ClassDB::bind_method(D_METHOD("get_smooth_normals"), &PathExtrudeProfileCircle::get_smooth_normals);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "smooth_normals"), "set_smooth_normals", "get_smooth_normals");
}