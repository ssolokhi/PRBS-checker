module prbs_checker #(parameter c_LOCK_THRESHOLD = 31, parameter c_OPEN_THRESHOLD = 31) (
    input i_clock,
    input i_received_prbs_bit,
    output o_is_locked,
    output o_error
    );  
    localparam OPEN = 1'b0;
    localparam LOCKED = 1'b1;
    reg [$clog2(c_LOCK_THRESHOLD)-1:0] r_lock_counter; // should only count consequtive errors
    reg [$clog2(c_OPEN_THRESHOLD)-1:0] r_open_counter;
    reg r_current_state = OPEN;
    reg r_error = 1'b0;
    reg r_expected_prbs_bit = 1'b0; // define properly

    always @(posedge i_clock)
    begin
        case (r_current_state)
            OPEN:
            begin
                if (i_received_prbs_bit != r_expected_prbs_bit) r_lock_counter <= 0; // because correct bits (if any) are not consequtive
                if (r_lock_counter < c_LOCK_THRESHOLD-1 && i_received_prbs_bit == r_expected_prbs_bit) r_lock_counter <= r_lock_counter + 1;
                if (r_lock_counter == c_LOCK_THRESHOLD-1)
                begin
                    r_lock_counter <= 0;
                    r_open_counter <= 0;
                    r_current_state <= LOCKED;
                end
            end
            LOCKED:
            begin
                if (i_received_prbs_bit == r_expected_prbs_bit) r_error <= 1'b0; 
                if (r_open_counter < c_OPEN_THRESHOLD-1 && i_received_prbs_bit != r_expected_prbs_bit) 
                begin
                    r_error <= 1'b1;
                    r_open_counter <= r_open_counter + 1;
                end
                if (r_open_counter == c_OPEN_THRESHOLD-1)
                begin
                    r_open_counter <= 0;
                    r_lock_counter <= 0;
                    r_current_state <= OPEN;
                end
            end
        endcase
    end
    assign o_error = (r_error) ? 1'b1 : 1'b0;
    assign o_is_locked = (r_current_state == LOCKED) ? 1'b1 : 1'b0;
endmodule
