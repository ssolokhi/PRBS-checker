`default_nettype none

module prbs_checker_tb ();
    import prbs_checker_fsm_states::*;
    localparam c_LOCK_THRESHOLD = 10;
    localparam c_OPEN_THRESHOLD = 5;
    localparam c_WAIT_FOR_SIGNALS_TO_SETTLE = 1;

    logic r_tb_clock = 1'b0;
    always #5 r_tb_clock <= !r_tb_clock;
    logic r_tb_reset = 1'b1;

    logic r_tb_received_bit = 1'b0;
    logic r_tb_expected_bit = 1'b1;

    logic r_tb_is_locked;
    logic r_tb_error;

    prbs_checker #(.c_LOCK_THRESHOLD(c_LOCK_THRESHOLD), .c_OPEN_THRESHOLD(c_OPEN_THRESHOLD)) UUT (
        .i_clock(r_tb_clock),
        .i_reset(r_tb_reset),
        .i_received_prbs_bit(r_tb_received_bit),
        .i_expected_prbs_bit(r_tb_expected_bit),
        .o_is_locked(r_tb_is_locked),
        .o_error(r_tb_error)
    );

/* verilator lint_off DECLFILENAME */
    covergroup cg_check_fsm_transition @(posedge r_tb_clock);
    // track transitions of signals below at each rising clock edge
        option.per_instance = 1;

        fsm_locked: coverpoint r_tb_is_locked {
            bins open_to_locked = (1'b0 => 1'b1);
            bins locked_to_open = (1'b1 => 1'b0);
            bins stay_open = (1'b0 => 1'b0);
            bins stay_locked = (1'b1 => 1'b1);
        }

        fsm_error: coverpoint r_tb_error {
            bins error_asserted = {1'b1};
            bins error_cleared = {1'b0};
        }
        // track combinations of the two
        fsm_cross_locked_error: cross fsm_locked, fsm_error;
    endgroup;
/* verilator lint_on DECLFILENAME */

    cg_check_fsm_transition cg_inst = new();

    initial begin
        $dumpfile("prbs_checker_tb.vcd");
        $dumpvars(0, prbs_checker_tb);

        // check reset
        cg_inst.stop(); // do not track transitions at reset
        force UUT.current_state = LOCKED; // otherwise check below is meaningless 
        r_tb_reset <= 1'b0;
        @(posedge r_tb_clock); 
        release UUT.current_state;
        #c_WAIT_FOR_SIGNALS_TO_SETTLE;
        a_reset_to_default_seed: assert (UUT.current_state == OPEN) else $error("%0t: FSM not in OPEN state after reset", $time);
        a_reset_lock_counter: assert (UUT.lock_counter == 0) else $error("%0t: FSM's lock counter did not return to 0 after reset", $time);
        a_reset_open_counter: assert (UUT.open_counter == 0) else $error("%0t: FSM's open counter did not return to 0 after reset", $time);
        r_tb_reset <= 1'b1;
        @(posedge r_tb_clock);
        cg_inst.start();

        // check OPEN stays OPEN if there are not enough matching bits
        r_tb_received_bit <= 1'b0;
        r_tb_expected_bit <= 1'b0;
        repeat(c_LOCK_THRESHOLD-1) @(posedge r_tb_clock);
        r_tb_received_bit <= 1'b1;
        r_tb_expected_bit <= 1'b0;
        @(posedge r_tb_clock);
        #c_WAIT_FOR_SIGNALS_TO_SETTLE;
        a_fsm_stays_open_correctly: assert (UUT.current_state == OPEN && r_tb_is_locked == 1'b0) else $error("%0t: FSM in LOCKED state after not enough (%d) matching bits", $time, c_LOCK_THRESHOLD-1);
        a_no_errors_when_open: assert (r_tb_error == 1'b0) else $error("%0t: FSM reported bit mismatch when OPEN", $time);

        // check OPEN -> LOCKED transition
        r_tb_received_bit <= 1'b0;
        r_tb_expected_bit <= 1'b0;
        repeat(c_LOCK_THRESHOLD) @(posedge r_tb_clock);
        #c_WAIT_FOR_SIGNALS_TO_SETTLE;
        a_fsm_locks_correctly: assert (UUT.current_state == LOCKED && r_tb_is_locked == 1'b1) else $error("%0t: FSM not in LOCKED state after enough (%d) matching bits", $time, c_LOCK_THRESHOLD);

        // check LOCKED stays LOCKED if there are not enough non-matching bits
        r_tb_received_bit <= 1'b1;
        r_tb_expected_bit <= 1'b0;
        repeat(c_OPEN_THRESHOLD-1) @(posedge r_tb_clock);
        #c_WAIT_FOR_SIGNALS_TO_SETTLE;
        a_error_on_bit_mismatch: assert (r_tb_error == 1'b1) else $error("%0t: FSM did not report bit mismatch when LOCKED", $time);
        r_tb_received_bit <= 1'b0;
        r_tb_expected_bit <= 1'b0;
        @(posedge r_tb_clock);
        #c_WAIT_FOR_SIGNALS_TO_SETTLE;
        a_fsm_stays_locked_correctly: assert (UUT.current_state == LOCKED && r_tb_is_locked == 1'b1) else $error("%0t: FSM in OPEN state after not enough (%d) non-matching bits", $time, c_LOCK_THRESHOLD-1);

        // check LOCKED -> OPEN transition
        r_tb_received_bit <= 1'b0;
        r_tb_expected_bit <= 1'b1;
        repeat(c_OPEN_THRESHOLD) @(posedge r_tb_clock);
        #c_WAIT_FOR_SIGNALS_TO_SETTLE;
        a_fsm_opens_correctly: assert (UUT.current_state == OPEN && r_tb_is_locked == 1'b0) else $error("%0t: FSM not in OPEN state after enough (%d) non-matching bits", $time, c_OPEN_THRESHOLD);

        // check that OPEN -> LOCKED transition can happen again
        r_tb_received_bit <= 1'b1;
        r_tb_expected_bit <= 1'b1;
        repeat(c_LOCK_THRESHOLD) @(posedge r_tb_clock);
        #c_WAIT_FOR_SIGNALS_TO_SETTLE;
        a_fsm_relocks_correctly: assert (UUT.current_state == LOCKED && r_tb_is_locked == 1'b1) else $error("%0t: FSM not in LOCKED state after enough (%d) matching bits", $time, c_LOCK_THRESHOLD);

        $display("%0t: SUCCESS: all checks passed!", $time);
        $display("Coverage is %0.2f %%", cg_inst.get_inst_coverage());
        $finish;
    end

    // In case the UUT hangs and never reaches $finish
    initial begin
        #1000;
        $error("ERROR: testbench timeout");
        $finish;
    end
endmodule
