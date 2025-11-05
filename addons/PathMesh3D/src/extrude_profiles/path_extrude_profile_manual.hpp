#pragma once

#include "path_extrude_profile_base.hpp"

namespace godot {

class PathExtrudeProfileManual : public PathExtrudeProfileBase {
    GDCLASS(PathExtrudeProfileManual, PathExtrudeProfileBase)

public:
    void set_manual_cross_section(const PackedVector2Array &p_cross_section);
    PackedVector2Array get_manual_cross_section() const;

    void set_smooth_normals(bool p_smooth_normals);
    bool get_smooth_normals() const;
    
    void set_closed(bool p_closed);
    bool get_closed() const;

protected:
    Array _generate_cross_section() override;

    static void _bind_methods();

private:
    PackedVector2Array manual_cross_section;
    bool smooth_normals = false;
    bool closed = true;
};

}