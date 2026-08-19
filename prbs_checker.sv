module prbs_checker #(parameter int c_LOCK_THRESHOLD = 31, parameter int c_OPEN_THRESHOLD = 31) (
    input logic i_clock,
    input logic i_received_prbs_bit,
    input logic i_expected_prbs_bit,
    output logic o_is_locked,
    output logic o_error
    );  

    typedef enum logic {
    OPEN, LOCKED
    } state;

    logic [$clog2(c_LOCK_THRESHOLD)-1:0] lock_counter; // should only count consequtive errors
    logic [$clog2(c_OPEN_THRESHOLD)-1:0] open_counter;
    state current_state = OPEN;
    logic error = 1'b0;

    always_ff @(posedge i_clock)
    begin
        case (current_state)
            OPEN:
            begin
                if (i_received_prbs_bit != i_expected_prbs_bit) lock_counter <= 0; // because correct bits (if any) are not consequtive
                if (lock_counter < c_LOCK_THRESHOLD-1 && i_received_prbs_bit == i_expected_prbs_bit) lock_counter <= lock_counter + 1;
                if (lock_counter == c_LOCK_THRESHOLD-1)
                begin
                    lock_counter <= 0;
                    open_counter <= 0;
                    current_state <= LOCKED;
                end
            end
            LOCKED:
            begin
                if (i_received_prbs_bit == i_expected_prbs_bit) error <= 1'b0; 
                if (open_counter < c_OPEN_THRESHOLD-1 && i_received_prbs_bit != i_expected_prbs_bit) 
                begin
                    error <= 1'b1;
                    open_counter <= open_counter + 1;
                end
                if (open_counter == c_OPEN_THRESHOLD-1)
                begin
                    open_counter <= 0;
                    lock_counter <= 0;
                    current_state <= OPEN;
                end
            end
        endcase
    end
    assign o_error = (error) ? 1'b1 : 1'b0;
    assign o_is_locked = (current_state == LOCKED) ? 1'b1 : 1'b0;
endmodule
