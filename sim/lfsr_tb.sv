`default_nettype none

module lfsr_tb ();
    localparam c_LFSR_BITS = 7; // to simulate quicker 

    localparam c_WAIT_AFTER_CLOCK_EDGE = 1; // to avoid race condition between posedge i_clock and negedge i_reset (async reset)

    logic r_tb_clock = 1'b0;
    always #5 r_tb_clock <= !r_tb_clock;
    logic r_tb_reset = 1'b1;

    logic r_tb_load_enable = 1'b0;
    logic r_tb_load_bit = 1'b0;
    logic r_tb_last_lfsr_bit;

    lfsr #(.c_LFSR_BITS(c_LFSR_BITS)) UUT (
        .i_clock(r_tb_clock),
        .i_reset(r_tb_reset),
        .i_load_enable(r_tb_load_enable),
        .i_load_bit(r_tb_load_bit),
        .o_last_lfsr_bit(r_tb_last_lfsr_bit)
    );

    function automatic [c_LFSR_BITS-1:0] get_next_state (input [c_LFSR_BITS-1:0] current_state);
        logic xor_gate;
        unique case (c_LFSR_BITS)
            7: xor_gate = lfsr_bits[6] ^ lfsr_bits[5];
            31: xor_gate = lfsr_bits[30] ^ lfsr_bits[27];
            default: xor_gate = 1'b0;   
        endcase
        return {current_state[c_LFSR_BITS-2:0], xor_gate};
    endfunction

    p_last_bit_sent_correctly: assert property (@(posedge r_tb_clock) UUT.lfsr_bits[c_LFSR_BITS-1] == r_tb_last_lfsr_bit) 
    else $error("%0t: LFSR did not send last bit correctly: expected %b, got %b", $time, UUT.lfsr_bits[c_LFSR_BITS-1], r_tb_last_lfsr_bit);

    initial begin
        assert (c_LFSR_BITS inside {7, 31}) else $error("Unsupported value of c_LFSR_BITS");

        // check reset (active-low!) to default seed value
        r_tb_reset <= 1'b0;
        @(posedge r_tb_clock);
        #c_WAIT_AFTER_CLOCK_EDGE; 
        a_reset_to_default_seed: assert (UUT.lfsr_bits == UUT.c_LFSR_SEED) 
        else $error("%0t: LFSR was not seeded correctly upon reset: expected %h, got %h", $time, UUT.c_LFSR_SEED, UUT.lfsr_bits);
        r_tb_reset <= 1'b1;
        @(posedge r_tb_clock);
        #c_WAIT_AFTER_CLOCK_EDGE; 

        // test bit loading
        @(posedge r_tb_clock);
        r_tb_load_enable <= 1'b1;
        #c_WAIT_AFTER_CLOCK_EDGE; 
        a_load_bit_to_lfsr: assert (UUT.lfsr_bits == {UUT.lfsr_bits[c_LFSR_BITS-2:0], r_tb_load_bit}) 
        else $error("%0t: LFSR bits do not match bits expected from contenating with loaded bit", $time);
        @(posedge r_tb_clock);
        r_tb_load_enable <= 1'b0;

        // check that output is based on XOR tap
        repeat(2*c_LFSR_BITS) begin
            logic [c_LFSR_BITS-1:0] expected_next_state = get_next_state(UUT.lfsr_bits); 
            @(posedge r_tb_clock);
            #c_WAIT_AFTER_CLOCK_EDGE;
            a_xor_appended_correctly: assert (expected_next_state == UUT.lfsr_bits) 
            else $error("%0t: LFSR bits do not match bits expected from contenating with XOR gate outputs", $time);
        end

        // check that there are 2^{c_LFSR_BITS} - 1 unique, non-zero states
        r_tb_reset <= 1'b0;
        @(posedge r_tb_clock);
        #c_WAIT_AFTER_CLOCK_EDGE; 
        r_tb_reset <= 1'b1;
        @(posedge r_tb_clock);
        #c_WAIT_AFTER_CLOCK_EDGE; 

        // state should now be the seed value
        begin
            automatic int c_LFSR_PERIOD = (2**c_LFSR_BITS) - 1; // to simulate quicker 
            automatic bit seen_states [logic [c_LFSR_BITS-1:0]]; // store true\false values per LFSR state, accessed via LFSR state
            for (int i = 0; i < c_LFSR_PERIOD; ++i) begin
                a_nonzero_state: assert (UUT.lfsr_bits != '0) else $error("%0t: LFSR in illegal all-zero state", $time);

                a_state_not_seen_before: assert (!seen_states.exists(UUT.lfsr_bits)) 
                else $error("%0t: LFSR state already seen before LFSR period exceeded: %h ", $time, UUT.lfsr_bits);

                seen_states[UUT.lfsr_bits] = 1'b1;
                @(posedge r_tb_clock);
                #c_WAIT_AFTER_CLOCK_EDGE;
            end
            a_return_to_seed: assert (UUT.lfsr_bits == UUT.c_LFSR_SEED) 
            else $error("%0t: LFSR bits did not cycle back to seed value after LFSR period", $time);
        end

        $display("%0t: SUCCESS: all checks passed!", $time);
        $finish;
    end

    // In case the UUT hangs and never reaches $finish
    initial begin
        #1000;
        $display("ERROR: testbench timeout");
        $finish;
    end
endmodule
