cmake_minimum_required(VERSION 3.29)
project(prbs_checker)
find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator not found!")
endif()
add_executable(VSimPrbsChecker sim_prbs_checker.cpp)
verilate(VSimPrbsChecker 
    SOURCES sim/prbs_checker_top_tb.sv TOP_MODULE prbs_checker_top_tb
    INCLUDE_DIRS src sim
    VERILATOR_ARGS --timing --coverage --trace-vcd)
