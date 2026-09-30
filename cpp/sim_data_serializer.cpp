#include <memory>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "VDataSerializerTb.h" // generated from verilating the SystemVeriolg file

int main(int argc, char **argv) {
    const int SIMULATION_TIME = 1000;
    const std::unique_ptr<VerilatedContext> verilatedContext{new VerilatedContext};
    verilatedContext->commandArgs(argc, argv);
    verilatedContext->traceEverOn(true);
    const std::unique_ptr<VerilatedVcdC> verilatedVcdC{new VerilatedVcdC};
    const std::unique_ptr<VDataSerializerTb> dataSerializer{new VDataSerializerTb{verilatedContext.get()}};
        while (verilatedContext->time() < SIMULATION_TIME && !verilatedContext->gotFinish()) {
        verilatedContext->timeInc(1);
        dataSerializer->eval();
    }
    return 0;
}
