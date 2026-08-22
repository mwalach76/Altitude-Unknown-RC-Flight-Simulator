cmake_minimum_required(VERSION 3.18)
project(rcflight_jsbsim LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(GODOTCPP_DEFAULT_API_VERSION "4.7" CACHE STRING "Godot API version")
set(GODOTCPP_TARGET template_debug CACHE STRING "Godot C++ target")
set(GODOTCPP_ENABLE_TESTING OFF CACHE BOOL "" FORCE)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(BUILD_PYTHON_MODULE OFF CACHE BOOL "" FORCE)
set(BUILD_JULIA_PACKAGE OFF CACHE BOOL "" FORCE)
set(BUILD_MATLAB_SFUNCTION OFF CACHE BOOL "" FORCE)
set(SYSTEM_EXPAT OFF CACHE BOOL "" FORCE)

add_subdirectory(third_party/godot-cpp)
add_subdirectory(third_party/jsbsim)

add_library(rcflight_jsbsim SHARED
    src/jsbsim_bridge.cpp
    src/register_types.cpp
)

target_include_directories(rcflight_jsbsim PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/jsbsim/src
)
target_link_libraries(rcflight_jsbsim PRIVATE godot-cpp libJSBSim)

set_target_properties(rcflight_jsbsim PROPERTIES
    PREFIX "lib"
    OUTPUT_NAME "rcflight_jsbsim"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin"
)
