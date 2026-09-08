#include <memory>
#include "verilated.h"
#include "Vprbs_checker_top_tb.h" // generated from verilating the SystemVeriolg file

int main(int argc, char **argv) {
    //Verilated::traceEverOn(true);
    const std::unique_ptr<VerilatedContext> verilatedContext{new VerilatedContext};
    verilatedContext->commandArgs(argc, argv);
    verilatedContext->traceEverOn(true);
    const std::unique_ptr<Vprbs_checker_top_tb> prbsCheckerTop{new Vprbs_checker_top_tb{verilatedContext.get()}};
    while (!verilatedContext->gotFinish()) {
        prbsCheckerTop->eval();
    }
    return 0;
}
