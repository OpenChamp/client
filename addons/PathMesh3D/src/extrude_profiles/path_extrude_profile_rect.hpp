#pragma once

#include "path_extrude_profile_base.hpp"

namespace godot {

class PathExtrudeProfileRect : public PathExtrudeProfileBase {
    GDCLASS(PathExtrudeProfileRect, PathExtrudeProfileBase)

public:
    void set_rect(const Rect2 &p_rect);
    Rect2 get_rect() const;

    void set_subdivisions(const Vector2i p_subdivisions);
    Vector2i get_subdivisions() const;

    void set_smooth_normals(const bool p_smooth_normals);
    bool get_smooth_normals() const;

protected:
    Array _generate_cross_section() override;
    static void _bind_methods();
    
private:
    Rect2 rect;
    Vector2i subdivisions;
    bool smooth_normals = false;
};

}