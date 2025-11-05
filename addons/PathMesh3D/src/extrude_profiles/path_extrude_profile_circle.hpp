#pragma once

#include "path_extrude_profile_base.hpp"

namespace godot {

class PathExtrudeProfileCircle : public PathExtrudeProfileBase {
    GDCLASS(PathExtrudeProfileCircle, PathExtrudeProfileBase)

public:
    void set_radius(const double p_radius);
    double get_radius() const;

    void set_starting_angle(const double p_starting_angle);
    double get_starting_angle() const;

    void set_ending_angle(const double p_ending_angle);
    double get_ending_angle() const;

    void set_smooth_normals(const bool p_smooth_normals);
    bool get_smooth_normals() const;

    void set_closed(const bool p_closed);
    bool is_closed() const;

    void set_segments(const uint64_t p_segments);
    uint64_t get_segments() const;

protected:
    virtual Array _generate_cross_section() override;
    static void _bind_methods();

private:
    double radius = 1.0;
    double starting_angle = 0.0;
    double ending_angle = Math_TAU;
    bool smooth_normals = true;
    bool closed = true;
    uint64_t segments = 32;
};

}