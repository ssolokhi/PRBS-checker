`default_nettype none

module prbs_checker_top_tb ();
    localparam c_PRBS_BITS = 7; // to simulate quicker 
    localparam c_WAIT_FOR_SIGNALS_TO_SETTLE = 1;

    logic r_tb_clock = 1'b0;
    always #5 r_tb_clock <= !r_tb_clock;
    logic r_tb_reset = 1'b1;

    logic r_tb_is_locked;
    logic r_tb_led_error;

    prbs_checker_top #(.c_PRBS_BITS(c_PRBS_BITS)) UUT (
        .i_clock(r_tb_clock),
        .i_reset(r_tb_reset),
        .o_led_locked(r_tb_is_locked),
        .o_led_error(r_tb_led_error)
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

        fsm_error: coverpoint r_tb_led_error {
            //bins error_asserted = (1'b0 => 1'b1);
            bins error_asserted = {1'b1};
            //bins error_cleared = (1'b1 => 1'b0);
            bins error_cleared = {1'b0};
            bins reserve = default;
        }
        // track combinations of the two
        fsm_cross_locked_error: cross fsm_locked, fsm_error;
    endgroup;
/* verilator lint_on DECLFILENAME */

    cg_check_fsm_transition cg_inst = new();

    initial begin
        assert (c_PRBS_BITS inside {7, 31}) else $error("Unsupported value of c_PRBS_BITS");

        $dumpfile("prbs_checker_top_tb.vcd");
        $dumpvars(0, prbs_checker_top_tb);

        // test reset functionality
        cg_inst.stop(); // do not track transitions at reset
        r_tb_reset <= 1'b0; // since it's active-low
        @(posedge r_tb_clock);
        #c_WAIT_FOR_SIGNALS_TO_SETTLE;
        a_load_counter_reset: assert (UUT.load_counter_rx == '0) else $error("%0t: Reset did not clear load counter", $time);
        a_load_enabled: assert (UUT.load_enable_rx == 1'b1) else $error("%0t: Reset did not enable bit loading", $time);
        r_tb_reset <= 1'b1;
        @(posedge r_tb_clock);
        cg_inst.start();

        // test FSM lock acquisition
        $display("%0t: waiting for RX PRBS checker to acquire lock", $time);
        wait (r_tb_is_locked == 1'b1); 
        $display("%0t: RX PRBS checker acquired lock", $time);

        $display("%0t: SUCCESS: all checks passed!", $time);
        $display("Coverage is %0.2f %%", cg_inst.get_coverage());
        $finish;
    end

    // In case the UUT hangs and never reaches $finish
    initial begin
        #1000;
        $error("ERROR: testbench timeout");
        $finish;
    end
endmodule
