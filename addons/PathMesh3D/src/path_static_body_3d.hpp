#pragma once

#include <godot_cpp/classes/static_body3d.hpp>

#include "path_tool.hpp"
#include "path_collision_tool.hpp"

namespace godot {

class MultiMeshInstance3D;

class PathStaticBody3D : public StaticBody3D {
    GDCLASS(PathStaticBody3D, StaticBody3D)
    PATH_TOOL(PathStaticBody3D, SHAPE)
    PATH_COLLISION_TOOL_HEADER(PathStaticBody3D, StaticBody3D, static_body)
};

}

VARIANT_ENUM_CAST(PathStaticBody3D::Distribution)
VARIANT_ENUM_CAST(PathStaticBody3D::Alignment)
VARIANT_ENUM_CAST(PathStaticBody3D::Rotation)
VARIANT_ENUM_CAST(PathStaticBody3D::RelativeTransform)