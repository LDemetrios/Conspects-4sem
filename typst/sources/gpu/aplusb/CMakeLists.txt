cmake_minimum_required(VERSION 3.28)
set(CMAKE_CXX_STANDARD 20)

project(Main)
add_executable(Main main.cpp utils.h utils.cpp wrappers.h wrappers.cpp)
target_compile_features(Main PRIVATE cxx_auto_type)

find_package(OpenCL REQUIRED)
target_link_libraries(Main OpenCL::OpenCL)
