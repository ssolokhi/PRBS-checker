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
    localparam int c_DEPTH_CLOG2 = $clog2(c_DEPTH);
    localparam logic [c_DEPTH_CLOG2:0] c_DEPTH_resized = (c_DEPTH_CLOG2 + 1)'(c_DEPTH);
    localparam logic [c_DEPTH_CLOG2:0] c_ALMOST_FULL_LEVEL_resized = (c_DEPTH_CLOG2 + 1)'(c_ALMOST_FULL_LEVEL);
    localparam logic [c_DEPTH_CLOG2:0] c_ALMOST_EMPTY_LEVEL_resized = (c_DEPTH_CLOG2 + 1)'(c_ALMOST_EMPTY_LEVEL);

    logic [c_WIDTH-1:0] fifo [c_DEPTH-1:0]; // declare FIFO as an array of memory
    // these addresses are 1 bit wider than the address because the extra bit
    // (MSB) distinguishes full case from empty case: 
    // both have read_pointer == write pointer, so matching extra bit can
    // indicate empty, and differing MSB - full 
    logic [c_DEPTH_CLOG2:0] write_address_binary, write_address_gray_encoded; 
    logic [c_DEPTH_CLOG2:0] read_address_binary, read_address_gray_encoded; 

    // chain 2 flip-flops together to reduce the chance of metastabile states
    logic [c_DEPTH_CLOG2:0] write_address_gray_encoded_1_cycle_delay, write_address_gray_encoded_2_cycles_delay; 
    logic [c_DEPTH_CLOG2:0] read_address_gray_encoded_1_cycle_delay, read_address_gray_encoded_2_cycles_delay; 

    // write domain
    logic is_write_allowed;
    assign is_write_allowed = i_write_enable && !o_is_full;

    always_ff @(posedge i_write_clock) begin
        if (!i_write_reset) begin
            write_address_binary <= '0;
            write_address_gray_encoded <= '0;
        end
        else if (is_write_allowed) begin
            fifo[write_address_binary[c_DEPTH_CLOG2-1:0]] <= i_write_data;
            write_address_binary <= write_address_binary + 1'b1;
        end
    end
    
    always_ff @(posedge i_write_clock) begin
         if (!i_write_reset) begin
            read_address_gray_encoded_1_cycle_delay <= '0;
            read_address_gray_encoded_2_cycles_delay <= '0;
        end
        else begin
            read_address_gray_encoded_1_cycle_delay <= read_address_gray_encoded;
            read_address_gray_encoded_2_cycles_delay <= read_address_gray_encoded_1_cycle_delay;
        end

    end

    assign o_is_full = ((write_address_binary) == c_DEPTH_resized);
    assign o_is_almost_full = ((write_address_binary) >= (c_DEPTH_resized - c_ALMOST_FULL_LEVEL_resized));

    // read domain
    logic is_read_allowed;
    assign is_read_allowed = i_read_enable && !o_is_empty;

    always_ff @(posedge i_read_clock) begin
        if (!i_read_reset) begin
            read_address_binary <= '0;
            read_address_gray_encoded <= '0;
        end
        else if (is_read_allowed) begin
            read_address_binary <= read_address_binary + 1'b1;
        end
    end
    
    always_ff @(posedge i_read_clock) begin
         if (!i_read_reset) begin
            write_address_gray_encoded_1_cycle_delay <= '0;
            write_address_gray_encoded_2_cycles_delay <= '0;
        end
        else begin
            write_address_gray_encoded_1_cycle_delay <= read_address_gray_encoded;
            write_address_gray_encoded_2_cycles_delay <= read_address_gray_encoded_1_cycle_delay;
        end

    end
    assign o_is_empty = ((read_address_binary) == 0);
    assign o_is_almost_empty = ((read_address_binary) <= c_ALMOST_EMPTY_LEVEL_resized);

    assign o_read_ready = !o_is_empty;
    assign o_read_data = fifo[read_address_binary[c_DEPTH_CLOG2-1:0]];
endmodule
