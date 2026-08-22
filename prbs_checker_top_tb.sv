module prbs_checker_top_tb ();
    localparam c_PRBS_BITS = 7;

    logic r_led_locked = 1'b0;
    logic r_led_error = 1'b0;
    
    logic r_tb_clock = 1'b0;
    always #5 r_tb_clock <= !r_tb_clock;
    logic r_tb_reset = 1'b1;
    
    logic received_prbs_bit_tx;
    logic expected_prbs_bit_rx;
    logic load_enable_tx = 1'b0;

    lfsr #(.c_LFSR_BITS(c_PRBS_BITS)) prbs_generator_tx (
        .i_clock(r_tb_clock),
        .i_reset(r_tb_reset),
        .i_load_enable(load_enable_tx),
        .i_load_bit(1'b0),
        .o_last_lfsr_bit(received_prbs_bit_tx)
    );

    lfsr #(.c_LFSR_BITS(c_PRBS_BITS)) prbs_generator_rx (
        .i_clock(r_tb_clock),
        .i_reset(r_tb_reset),
        .i_load_enable(load_enable_rx),
        .i_load_bit(received_prbs_bit_tx),
        .o_last_lfsr_bit(expected_prbs_bit_rx)
    );

    logic load_enable_rx = 1'b1;
    logic [$clog2(c_PRBS_BITS)-1:0] load_counter_rx = '0;

    always_ff @(posedge r_tb_clock or negedge r_tb_reset) begin
        if (!r_tb_reset) begin
            load_counter_rx <= '0;
            load_enable_rx <= 1'b1;
        end
        else if (load_enable_rx) begin
            if (load_counter_rx == c_PRBS_BITS - 1) begin
                load_counter_rx <= '0;
                load_enable_rx <= 1'b0;
            end
            else load_counter_rx <= load_counter_rx + 1;
        end
    end

    prbs_checker #(.c_LOCK_THRESHOLD(c_PRBS_BITS), .c_OPEN_THRESHOLD(c_PRBS_BITS)) prbs_checker_rx (
        .i_clock(r_tb_clock),
        .i_received_prbs_bit(received_prbs_bit_tx),
        .i_expected_prbs_bit(expected_prbs_bit_rx),
        .o_is_locked(o_led_locked),
        .o_error(o_led_error)
    );

    initial begin
        #100;
    end
endmodule
