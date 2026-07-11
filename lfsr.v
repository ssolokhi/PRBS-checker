module lfsr #(parameter c_LFSR_BITS = 10) (
    input i_clock,
    output o_last_lfsr_bit,
    );
    reg [c_LFSR_BITS-1:0] r_LFSR;
    wire w_XNOR_gate;
    
    always @(posedge i_clock)
    begin
       r_LFSR <= {r_LFSR[c_LFSR_BITS-2:0], w_XNOR_gate}; 
    end
    assign o_last_lfsr_bit = r_LFSR[c_LFSR_BITS-1]; // transmit 1 bit per clock cycle
    assign w_XNOR_gate = r_LFSR[c_LFSR_BITS-1] ^ ~r_LFSR[c_LFSR_BITS-2]; 
endmodule
