module lfsr #(
    parameter int c_LFSR_BITS = 7,
    parameter logic [c_LFSR_BITS-1:0] c_LFSR_SEED = 'h1 // since all-zero seed is not allowed
) (
    input logic i_clock,
    input logic i_reset, // active-low reset to improve noise immunity
    output logic o_last_lfsr_bit
);
    logic [c_LFSR_BITS-1:0] lfsr_bits;
    logic xor_gate;
    
    always_ff @(posedge i_clock or negedge i_reset) begin
       if (!i_reset) lfsr_bits <= c_LFSR_SEED;
    else 
       lfsr_bits <= {lfsr_bits[c_LFSR_BITS-2:0], xor_gate}; 
    end
    assign o_last_lfsr_bit = lfsr_bits[c_LFSR_BITS-1]; // transmit 1 bit per clock cycle
    assign xor_gate = lfsr_bits[c_LFSR_BITS-1] ^ lfsr_bits[c_LFSR_BITS-2]; 
endmodule
