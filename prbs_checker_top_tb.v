module prbs_checker_top ();
    localparam c_PRBS_BITS = 4;

    reg r_led_locked = 1'b0;
    reg r_led_error = 1'b0;
    
    reg r_tb_clock = 1'b0;
    always #5 r_tb_clock <= !r_tb_clock;
    
    wire w_prbs_bit;

    lfsr #(.c_LFSR_BITS(c_PRBS_BITS)) prbs_generator (
        .i_clock(r_tb_clock),
        .o_last_lfsr_bit(w_prbs_bit)
    );

    prbs_checker #(.c_LOCK_THRESHOLD(c_PRBS_BITS), .c_OPEN_THRESHOLD(c_PRBS_BITS)) prbs_checker (
        .i_clock(r_tb_clock),
        .i_received_prbs_bit(w_prbs_bit),
        .o_is_locked(r_led_locked),
        .o_error(r_led_error)
    );
    initial begin
        #100;
    end
endmodule
