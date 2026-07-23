module prbs_checker_top (
    input i_clock,
    output o_led_locked,
    output o_led_error
    );
    localparam c_PRBS_BITS = 31;
    wire w_prbs_bit;

    lfsr #(.c_LFSR_BITS(c_PRBS_BITS)) prbs_generator (
        .i_clock(i_clock),
        .o_last_lfsr_bit(w_prbs_bit)
    );

    prbs_checker #(.c_LOCK_THRESHOLD(c_PRBS_BITS), .c_OPEN_THRESHOLD(c_PRBS_BITS)) prbs_checker (
        .i_clock(i_clock),
        .i_received_prbs_bit(w_prbs_bit),
        .o_is_locked(o_led_locked),
        .o_error(o_led_error)
    );
endmodule
