`default_nettype none

module prbs_checker_top_tb ();
    localparam c_PRBS_BITS = 7; // to simulate quicker, use 

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


    initial begin
        r_tb_reset <= 1'b1;
        repeat(2) @(posedge r_tb_clock);
        r_tb_reset <= 1'b0;

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
        $finish;
    end

    // In case the UUT hangs and never reaches $finish
    initial begin
        #1000;
        $display("ERROR: testbench timeout");
        $finish;
    end
endmodule
