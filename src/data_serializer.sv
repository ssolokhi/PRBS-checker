`timescale 1ns/1ps
`default_nettype none

module data_serializer #(
    c_N_LANES = 2
)(
    input logic i_clock,
    input logic i_reset, // active-low
    input logic [c_N_LANES-1:0] i_parallel_data,
    input logic i_parallel_data_ready,
    output logic o_serial_data
);
    logic [c_N_LANES-1:0] bits_remaining_in_word;
    logic [c_N_LANES-1:0] shift_register;

    always_ff @(posedge i_clock) begin
        if (!i_reset) begin
            bits_remaining_in_word <= '0;
            shift_register <= '0;
        end
        else begin
            if (bits_remaining_in_word == 0) begin
                if (i_parallel_data_ready) begin
                    bits_remaining_in_word <= i_parallel_data;
                    bits_remaining_in_word <= c_N_LANES;
                end
            end
            else begin
                bits_remaining_in_word <= bits_remaining_in_word - 1'b1;
                shift_register <= shift_register >> 1;
            end
        end
    end

    assign o_serial_data = shift_register[0];
endmodule

