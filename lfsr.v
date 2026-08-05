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

    // select bit to XOR; see README for details
    always_comb begin
        unique case (c_LFSR_BITS)
            // PRBS-7 polynomial is x**7 + x**6 + 1
            7: xor_gate = lfsr_bits[6] ^ lfsr_bits[5];
            // PRBS-31 polynomial is x**31 + x**28 + 1
            31: xor_gate = lfsr_bits[30] ^ lfsr_bits[27];

            default: xor_gate = '0;    
        endcase
    end
    
    always_ff @(posedge i_clock or negedge i_reset) begin
       if (!i_reset) lfsr_bits <= c_LFSR_SEED;
    else 
       lfsr_bits <= {lfsr_bits[c_LFSR_BITS-2:0], xor_gate}; 
    end
    assign o_last_lfsr_bit = lfsr_bits[c_LFSR_BITS-1]; // transmit 1 bit per clock cycle
endmodule
