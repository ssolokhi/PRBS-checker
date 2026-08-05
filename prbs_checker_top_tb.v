module prbs_checker_top_tb ();
    localparam c_PRBS_BITS = 4;

    logic r_led_locked = 1'b0;
    logic r_led_error = 1'b0;
    
    logic r_tb_clock = 1'b0;
    logic r_tb_reset = 1'b1;
    always #5 r_tb_clock <= !r_tb_clock;
    
    logic prbs_bit;

    lfsr #(.c_LFSR_BITS(c_PRBS_BITS)) prbs_generator (
        .i_clock(r_tb_clock),
        .i_reset(r_tb_reset),
        .o_last_lfsr_bit(prbs_bit)
    );

    prbs_checker #(.c_LOCK_THRESHOLD(c_PRBS_BITS), .c_OPEN_THRESHOLD(c_PRBS_BITS)) prbs_checker (
        .i_clock(r_tb_clock),
        .i_received_prbs_bit(prbs_bit),
        .o_is_locked(r_led_locked),
        .o_error(r_led_error)
    );
    initial begin
        #100;
    end
endmodule
