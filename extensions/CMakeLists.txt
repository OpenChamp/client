cmake_minimum_required(VERSION 3.13)
project(openchamp LANGUAGES CXX)

if (GODOT_DISABLE_EXCEPTIONS)
	if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
		set(GODOT_COMPILE_FLAGS "${GODOT_COMPILE_FLAGS} -D_HAS_EXCEPTIONS=0")
	else()
		set(GODOT_COMPILE_FLAGS "${GODOT_COMPILE_FLAGS} -fno-exceptions")
	endif()
else()
	if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
		set(GODOT_COMPILE_FLAGS "${GODOT_COMPILE_FLAGS} /EHsc")
	endif()
endif()

# set the sources and headers
set(SOURCES
    src/register_types.cpp
    src/identifier.cpp
)
include_directories(include)

add_library(openchamp SHARED ${SOURCES})

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)

# rename the output file and update the install location
string(TOLOWER ${CMAKE_SYSTEM_NAME} SYSTEM_NAME_LOWER)
string(TOLOWER ${CMAKE_BUILD_TYPE} BUILD_TYPE_LOWER)
string(TOLOWER ${CMAKE_SYSTEM_PROCESSOR} SYSTEM_PROCESSOR_LOWER)

set_target_properties(openchamp PROPERTIES OUTPUT_NAME openchamp.${SYSTEM_NAME_LOWER}.template_${BUILD_TYPE_LOWER}.${SYSTEM_PROCESSOR_LOWER})
install(TARGETS openchamp DESTINATION ${CMAKE_SOURCE_DIR}/../bin)

# Add the godot-cpp library
add_subdirectory(godot-cpp)
target_link_libraries(openchamp godot-cpp)

# Use the godot-cpp compile arguments for this as well
set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY COMPILE_FLAGS ${GODOT_COMPILE_FLAGS})
