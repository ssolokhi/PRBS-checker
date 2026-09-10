#include <memory>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "VLfsrTb.h" // generated from verilating the SystemVeriolg file

int main(int argc, char **argv) {
    const int SIMULATION_TIME = 1000;
    const std::unique_ptr<VerilatedContext> verilatedContext{new VerilatedContext};
    verilatedContext->commandArgs(argc, argv);
    verilatedContext->traceEverOn(true);
    const std::unique_ptr<VerilatedVcdC> verilatedVcdC{new VerilatedVcdC};
    const std::unique_ptr<VLfsrTb> lfsr{new VLfsrTb{verilatedContext.get()}};
    while (verilatedContext->time() < SIMULATION_TIME && !verilatedContext->gotFinish()) {
        verilatedContext->timeInc(1);
        lfsr->eval();
    }
    return 0;
}
