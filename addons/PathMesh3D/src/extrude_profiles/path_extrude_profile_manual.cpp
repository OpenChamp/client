#include "path_extrude_profile_manual.hpp"

#include <godot_cpp/classes/mesh.hpp>

using namespace godot;

void PathExtrudeProfileManual::set_manual_cross_section(const PackedVector2Array &p_cross_section) { 
    if (p_cross_section != manual_cross_section) {
        manual_cross_section = p_cross_section; 
        queue_update();
    }
}

PackedVector2Array PathExtrudeProfileManual::get_manual_cross_section() const {
    return manual_cross_section; 
}

void PathExtrudeProfileManual::set_smooth_normals(bool p_smooth_normals) {
    if (p_smooth_normals != smooth_normals) {
        smooth_normals = p_smooth_normals;
        queue_update();
    }
}

bool PathExtrudeProfileManual::get_smooth_normals() const { 
    return smooth_normals; 
}

void PathExtrudeProfileManual::set_closed(bool p_closed) {
    if (p_closed != closed) {
        closed = p_closed;
        queue_update();
    }
}

bool PathExtrudeProfileManual::get_closed() const { 
    return closed; 
}

Array PathExtrudeProfileManual::_generate_cross_section()  { 
    if (manual_cross_section.is_empty()) {
        return Array::make(PackedVector2Array());
    }

    Vector2 start = manual_cross_section[0];
    Vector2 end = manual_cross_section[manual_cross_section.size() - 1];
    bool already_closed = start.distance_squared_to(end) < 1.0e-6;

    PackedVector2Array cs;
    PackedVector2Array norms;

    if (smooth_normals) {
        cs = manual_cross_section;
        norms.resize(cs.size());
        for (uint64_t i = 0; i < cs.size(); ++i) {
            Vector2 start_last_segment = i == 0 ? 
                (already_closed ? end : start) : manual_cross_section[i - 1];
            Vector2 end_last_segment = manual_cross_section[i];
            
            Vector2 start_next_segment = manual_cross_section[i];
            Vector2 end_next_segment = i == manual_cross_section.size() - 1 ? 
                (already_closed ? start : end) : manual_cross_section[i + 1];

            Vector2 smoothed_normal = (end_last_segment - start_last_segment) + (end_next_segment - start_next_segment);
            norms[i] = smoothed_normal.normalized();
        }
    } else {
        for (uint64_t i = 0; i < manual_cross_section.size() - 1; ++i) {
            Vector2 p1 = manual_cross_section[i];
            Vector2 p2 = manual_cross_section[i + 1];
            Vector2 segment = p2 - p1;
            Vector2 segment_normal = Vector2(segment.y, -segment.x).normalized();
            cs.push_back(p1);
            cs.push_back(p2);
            norms.push_back(segment_normal);
            norms.push_back(segment_normal);
        }
    }

    if (closed && !already_closed) {
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
    out[Mesh::ARRAY_TEX_UV] = _generate_v(cs);
    return out;
}

void PathExtrudeProfileManual::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_manual_cross_section", "cross_section"), &PathExtrudeProfileManual::set_manual_cross_section);
    ClassDB::bind_method(D_METHOD("get_manual_cross_section"), &PathExtrudeProfileManual::get_manual_cross_section);
    ADD_PROPERTY(PropertyInfo(Variant::PACKED_VECTOR2_ARRAY, "cross_section"), "set_manual_cross_section", "get_manual_cross_section");

    ClassDB::bind_method(D_METHOD("set_closed", "closed"), &PathExtrudeProfileManual::set_closed);
    ClassDB::bind_method(D_METHOD("get_closed"), &PathExtrudeProfileManual::get_closed);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "closed"), "set_closed", "get_closed");

    ClassDB::bind_method(D_METHOD("set_smooth_normals", "smooth_normals"), &PathExtrudeProfileManual::set_smooth_normals);
    ClassDB::bind_method(D_METHOD("get_smooth_normals"), &PathExtrudeProfileManual::get_smooth_normals);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "smooth_normals"), "set_smooth_normals", "get_smooth_normals");
}