cmake_minimum_required(VERSION 3.29)
project(prbs_checker)
find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator not found!")
endif()

add_executable(VSimLfsr cpp/sim_lfsr.cpp)
verilate(VSimLfsr
    SOURCES sim/lfsr_tb.sv TOP_MODULE lfsr_tb
    PREFIX VLfsrTb
    INCLUDE_DIRS src sim
    VERILATOR_ARGS -Wno-initialdly --timing --trace-vcd)

add_executable(VSimDataSerializer cpp/sim_data_serializer.cpp)
verilate(VSimDataSerializer
    SOURCES sim/data_serializer_tb.sv TOP_MODULE data_serializer_tb
    PREFIX VDataSerializerTb
    INCLUDE_DIRS src sim
    VERILATOR_ARGS -Wno-initialdly --timing --coverage --trace-vcd)

add_executable(VSimCdcFifo cpp/sim_cdc_fifo.cpp)
verilate(VSimCdcFifo
    SOURCES sim/cdc_fifo_tb.sv TOP_MODULE cdc_fifo_tb
    PREFIX VCdcFifoTb
    INCLUDE_DIRS src sim
    VERILATOR_ARGS -Wno-initialdly --timing --trace-vcd)

add_executable(VSimPrbsChecker cpp/sim_prbs_checker.cpp)
verilate(VSimPrbsChecker
    SOURCES sim/prbs_checker_tb.sv src/prbs_checker_fsm_states.sv TOP_MODULE prbs_checker_tb
    PREFIX VPrbsCheckerTb
    INCLUDE_DIRS src sim
    VERILATOR_ARGS -Wno-initialdly -Wno-declfilename -Wno-coverign --timing --coverage --trace-vcd)

add_executable(VSimPrbsCheckerTop cpp/sim_prbs_checker_top.cpp)
verilate(VSimPrbsCheckerTop
    SOURCES sim/prbs_checker_top_tb.sv src/prbs_checker_fsm_states.sv TOP_MODULE prbs_checker_top_tb
    PREFIX VPrbsCheckerTopTb
    INCLUDE_DIRS src sim
    VERILATOR_ARGS -Wno-initialdly --timing --trace-vcd)
