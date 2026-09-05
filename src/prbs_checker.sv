`default_nettype none

module prbs_checker #(
    parameter int c_LOCK_THRESHOLD = 31,
    parameter int c_OPEN_THRESHOLD = 31,
    // int = 32 bits wide. To compare thresholds with counters without warnings from linter,
    // thresholds have to be resized to be same width as counters
    parameter logic [$clog2(c_LOCK_THRESHOLD)-1:0] c_LOCK_THRESHOLD_resized = $clog2(c_LOCK_THRESHOLD)'(c_LOCK_THRESHOLD),
    parameter logic [$clog2(c_OPEN_THRESHOLD)-1:0] c_OPEN_THRESHOLD_resized = $clog2(c_OPEN_THRESHOLD)'(c_OPEN_THRESHOLD)
    ) (
    input logic i_clock,
    input logic i_reset, // active-low
    input logic i_received_prbs_bit,
    input logic i_expected_prbs_bit,
    output logic o_is_locked,
    output logic o_error
    );  

    typedef enum logic {
    OPEN, LOCKED
    } state;

    logic [$clog2(c_LOCK_THRESHOLD)-1:0] lock_counter = 'b0;
    logic [$clog2(c_OPEN_THRESHOLD)-1:0] open_counter = 'b0;
    state current_state = OPEN;
    logic error = 1'b0;

    always_ff @(posedge i_clock)
    begin
        if (!i_reset) begin
            current_state <= OPEN;
            lock_counter <= 0;
            open_counter <= 0;
        end
        else begin
            case (current_state)
                OPEN:
                begin
                    error <= 1'b0; // error is meaningless when FSM not locked

                    if (i_received_prbs_bit == i_expected_prbs_bit) begin
                        if (lock_counter == c_LOCK_THRESHOLD_resized-1) begin
                            lock_counter <= 0;
                            open_counter <= 0;
                            current_state <= LOCKED;
                        end
                        else lock_counter <= lock_counter + 1;
                    end
                    else lock_counter <= 0; // because correct bits (if any) are not consecutive
                end
                end
                LOCKED:
                begin
                    if (i_received_prbs_bit != i_expected_prbs_bit) error <= 1'b1;
                    else if (i_received_prbs_bit != i_expected_prbs_bit) error <= 1'b0;

                    if (i_received_prbs_bit != i_expected_prbs_bit) begin
                        error <= 1'b1;
                        if (open_counter == c_OPEN_THRESHOLD_resized-1) begin
                            lock_counter <= 0;
                            open_counter <= 0;
                            current_state <= OPEN;
                        end
                        else open_counter <= open_counter + 1;
                    end
                    else begin
                        error <= 1'b0;
                        open_counter <= 0; // because incorrect bits are not consecutive
                    end
                end
            endcase
        end
    end
    assign o_error = (error) ? 1'b1 : 1'b0;
    assign o_is_locked = (current_state == LOCKED) ? 1'b1 : 1'b0;
endmodule
