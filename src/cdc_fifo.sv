`default_nettype none

module cdc_fifo #(
    parameter int c_WIDTH = 16, 
    parameter int c_DEPTH = 32, 
    parameter int c_ALMOST_FULL_LEVEL = 2, 
    parameter int c_ALMOST_EMPTY_LEVEL = 2
    ) (
    // write
    input logic i_write_clock,
    input logic i_write_reset, // active-low
    input logic i_write_enable,
    input logic [c_WIDTH-1:0] i_write_data,
    output logic o_is_full,
    output logic o_is_almost_full,
    // read
    input logic i_read_clock,
    input logic i_read_reset, // active-low
    input logic i_read_enable,
    output logic [c_WIDTH-1:0] o_read_data,
    output logic o_read_ready,
    output logic o_is_empty,
    output logic o_is_almost_empty
    );
    // int = 32 bits wide. To compare thresholds with counters without warnings from linter,
    // thresholds have to be resized to be same width as counters
    localparam logic [$clog2(c_DEPTH):0] c_DEPTH_resized = ($clog2(c_DEPTH) + 1)'(c_DEPTH);
    localparam logic [$clog2(c_DEPTH):0] c_ALMOST_FULL_LEVEL_resized = ($clog2(c_DEPTH) + 1)'(c_ALMOST_FULL_LEVEL);
    localparam logic [$clog2(c_DEPTH):0] c_ALMOST_EMPTY_LEVEL_resized = ($clog2(c_DEPTH) + 1)'(c_ALMOST_EMPTY_LEVEL);
    int element_count = 'd0;

    logic [c_WIDTH-1:0] fifo [c_DEPTH-1:0]; // declare FIFO as an array of memory
    // these addresses are 1 bit wider than the address because the extra bit
    // (MSB) distinguishes full case from empty case: 
    // both have read_pointer == write pointer, so matching extra bit can
    // indicate empty, and differing MSB - full 
    logic [$clog2(c_DEPTH):0] write_address_binary, write_address_gray_encoded; 
    logic [$clog2(c_DEPTH):0] read_address_binary, read_address_gray_encoded; 

    // write domain
    always_ff @(posedge i_write_clock) begin
    end

    // read domain
    always_ff @(posedge i_read_clock) begin
    end

    assign o_read_ready = i_read_enable;
    assign o_read_data = fifo[read_address];
    assign o_is_full = (element_count == c_DEPTH) || (element_count == c_DEPTH - 1 && i_write_enable && !i_read_enable);
    assign o_is_almost_full = (element_count > c_DEPTH - c_ALMOST_FULL_LEVEL);
    assign o_is_empty = (element_count == 0);
    assign o_is_almost_empty = (element_count < c_ALMOST_EMPTY_LEVEL);
endmodule
