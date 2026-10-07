`default_nettype none

module data_serializer #(
    parameter int c_N_LANES = 2
)(
    input logic i_clock,
    input logic i_reset, // active-low
    input logic [c_N_LANES-1:0] i_parallel_data,
    input logic i_parallel_data_ready,
    output logic o_serial_data,
    output logic o_ready_for_new_data
);
    parameter logic [$clog2(c_N_LANES)-1:0] c_N_LANES_resized = $clog2(c_N_LANES)'(c_N_LANES);

    logic [$clog2(c_N_LANES)-1:0] bits_remaining_in_word;
    logic [c_N_LANES-1:0] shift_register;

    always_ff @(posedge i_clock) begin
        if (!i_reset) begin
            bits_remaining_in_word <= '0;
            shift_register <= '0;
        end
        else begin
            if (bits_remaining_in_word == 0) begin
                if (i_parallel_data_ready) begin
                    bits_remaining_in_word <= c_N_LANES_resized - 1; // because 1 bit is already serialized at cycle 0
                    shift_register <= i_parallel_data;
                end
            end
            else begin
                bits_remaining_in_word <= bits_remaining_in_word - 1'b1;
                shift_register <= shift_register >> 1;
            end
        end
    end

    assign o_serial_data = shift_register[0];
    assign o_ready_for_new_data = (bits_remaining_in_word == 0) && i_parallel_data_ready;
endmodule

