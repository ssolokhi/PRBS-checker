module prbs_checker_top (
    input logic i_clock,
    input logic i_reset,
    output logic o_led_locked,
    output logic o_led_error
    );
    localparam c_PRBS_BITS = 31;
    logic prbs_bit;

    lfsr #(.c_LFSR_BITS(c_PRBS_BITS)) prbs_generator_tx (
        .i_clock(i_clock),
        .i_reset(i_reset),
        .o_last_lfsr_bit(prbs_bit)
    );

    prbs_checker #(.c_LOCK_THRESHOLD(c_PRBS_BITS), .c_OPEN_THRESHOLD(c_PRBS_BITS)) prbs_checker_rx (
        .i_clock(i_clock),
        .i_received_prbs_bit(prbs_bit),
        .o_is_locked(o_led_locked),
        .o_error(o_led_error)
    );
endmodule
