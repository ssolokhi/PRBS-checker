#include "verilated.h"
#include "Vout.h"

int main(int argc, char **argv) {
    VerilatedContext *verilatedContext = new VerilatedContext();
    verilatedContext->commandArgs(argc, argv);
    Vour *vour = new Vour{verilatedContext};
    while (!verilatedContext->gotFinish()) {
        vour->eval();
    }
    delete vour;
    delete verilatedContext;
    return 0;
}
