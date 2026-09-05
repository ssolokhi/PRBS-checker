`default_nettype none

module prbs_checker_top_tb ();
    localparam c_PRBS_BITS = 7; // to simulate quicker 

    logic r_tb_clock = 1'b0;
    always #5 r_tb_clock <= !r_tb_clock;
    logic r_tb_reset = 1'b1;

    logic r_tb_is_locked;
    logic r_tb_led_error;

    prbs_checker_top #(.c_LFSR_BITS(c_PRBS_BITS)) UUT (
        .i_clock(r_tb_clock),
        .i_reset(r_tb_reset),
        .o_led_locked(r_tb_is_locked),
        .o_led_error(r_tb_led_error)
    );

    // override received bit inside UUT for 1 clock cycle to mimic bit errror
    task automatic inject_bit_error();
        force UUT.received_prbs_bit_tx = ~UUT.received_prbs_bit_tx;
        @(posedge r_tb_clock);
        release UUT.received_prbs_bit_tx;
    endtask

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

        fsm_error: coverpoint r_tb_led_error {
            bins error_asserted = (1'b0 => 1'b1);
            bins error_cleared = (1'b1 => 1'b0);
            bins reserve = default;
        }
        // track combinations of the two
        fsm_cross_locked_error: cross fsm_locked, fsm_error;
    endgroup;
/* verilator lint_on DECLFILENAME */
    cg_check_fsm_transition cg_inst = new();

    initial begin
        assert (c_PRBS_BITS inside {7, 31}) else $error("Unsupported value of c_PRBS_BITS");
        // test reset functionality
        cg_inst.stop(); // do not track transitions at reset
        r_tb_reset <= 1'b0; // since it's active-low
        repeat(2) @(posedge r_tb_clock);
        r_tb_reset <= 1'b1;
        repeat(2) @(posedge r_tb_clock);
        cg_inst.start();

        // test FSM state transitionss
        wait (r_tb_is_locked == 1'b1); 
        $display("%0t: RX PRBS checker acquired lock", $time);
        a_error_led_before_error: assert (r_tb_led_error == 1'b0) else $error("%0t: error LED driven before actual error detected", $time);

        inject_bit_error();
        @(posedge r_tb_clock);
        a_let_error_slip: assert (r_tb_led_error == 1'b1) else $error("%0t: error LED not despite actual error", $time);

        // check FSM hysteresis
        repeat(3) @(posedge r_tb_clock);
        a_lock_not_lost: assert (r_tb_is_locked == 1'b1) else $error("%0t: Lock lost despite few errors", $time);

        repeat(c_PRBS_BITS+1) inject_bit_error();
        a_lock_lost: assert (r_tb_is_locked == 1'b0) else $error("%0t: Lock not lost despite many errors", $time);

        $display("%0t: SUCCESS: all checks passed!", $time);
        $display("Coverage is %0.2f% %", cg_inst.get_coverage());
        $finish;
    end

    // In case the UUT hangs and never reaches $finish
    initial begin
        #1000;
        $display("ERROR: testbench timeout");
        $finish;
    end
endmodule
