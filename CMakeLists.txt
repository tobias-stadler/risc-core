cmake_minimum_required(VERSION 3.12)
project(risc-core)
find_package(verilator)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 17)
add_compile_options(-Wall -Wextra -Wno-unused-parameter -Wno-unused-function)

add_executable(VPlaygroundTB sim/PlaygroundTB.cpp sim/Instr.cpp)
verilate(VPlaygroundTB TRACE SOURCES hw/PlaygroundTB.sv INCLUDE_DIRS hw/ VERILATOR_ARGS -Wall)

