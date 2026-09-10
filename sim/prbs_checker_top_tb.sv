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
    initial begin
        assert (c_PRBS_BITS inside {7, 31}) else $error("Unsupported value of c_PRBS_BITS");

        $dumpfile("prbs_checker_top_tb.vcd");
        $dumpvars(0, prbs_checker_top_tb);

        // test reset functionality
        r_tb_reset <= 1'b0; // since it's active-low
        @(posedge r_tb_clock);
        #c_WAIT_FOR_SIGNALS_TO_SETTLE;
        a_load_counter_reset: assert (UUT.load_counter_rx == '0) else $error("%0t: Reset did not clear load counter", $time);
        a_load_enabled: assert (UUT.load_enable_rx == 1'b1) else $error("%0t: Reset did not enable bit loading", $time);
        r_tb_reset <= 1'b1;
        @(posedge r_tb_clock);

        // test FSM lock acquisition
        $display("%0t: waiting for RX PRBS checker to acquire lock", $time);
        wait (r_tb_is_locked == 1'b1); 
        $display("%0t: RX PRBS checker acquired lock", $time);

        $display("%0t: SUCCESS: all checks passed!", $time);
        $finish;
    end

    // In case the UUT hangs and never reaches $finish
    initial begin
        #1000;
        $error("ERROR: testbench timeout");
        $finish;
    end
endmodule
