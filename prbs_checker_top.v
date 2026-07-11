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
endmodule
