#pragma once

#include <godot_cpp/classes/area3d.hpp>

#include "path_tool.hpp"
#include "path_collision_tool.hpp"

namespace godot {

class MultiMeshInstance3D;

class PathArea3D : public Area3D {
    GDCLASS(PathArea3D, Area3D)
    PATH_TOOL(PathArea3D, SHAPE)
    PATH_COLLISION_TOOL_HEADER(PathArea3D, Area3D, area)
};

} // namespace godot

VARIANT_ENUM_CAST(PathArea3D::Distribution)
VARIANT_ENUM_CAST(PathArea3D::Alignment)
VARIANT_ENUM_CAST(PathArea3D::Rotation)
VARIANT_ENUM_CAST(PathArea3D::RelativeTransform)