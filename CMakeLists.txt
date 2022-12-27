cmake_minimum_required(VERSION 3.12)
project(risc-core)
find_package(verilator)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(VDecoderTB sim/DecoderTB.cpp)
verilate(VDecoderTB TRACE SOURCES hw/DecoderTB.sv INCLUDE_DIRS hw/ VERILATOR_ARGS -Wall)
