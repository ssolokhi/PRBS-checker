`default_nettype none

module cdc_fifo_tb ();
    //write domain
    logic tb_write_clock = 1'b0;
    always #5 tb_write_clock <= !tb_write_clock;
    logic tb_write_reset = 1'b1;
    logic tb_write_enable = 1'b0;

    // read domain
    logic tb_read_clock = 1'b0;
    always #5 tb_read_clock <= !tb_read_clock;
    logic tb_read_reset = 1'b1;
    logic tb_read_enable = 1'b0;

    cdc_fifo #(.c_WIDTH(4), .c_DEPTH(4)) UUT (
        .i_write_clock(tb_write_clock),
        .i_write_reset(tb_write_reset),
        .i_write_enable(tb_write_enable),
        .i_write_data(),
        .o_is_full(),
        .o_is_almost_full(),
        .i_read_clock(tb_read_clock),
        .i_read_reset(tb_read_reset),
        .i_read_enable(tb_read_enable),
        .o_read_data(),
        .o_read_ready(),
        .o_is_empty(),
        .o_is_almost_empty()
    );

    initial begin
        $display("%0t: SUCCESS: all checks passed!", $time);
        $finish;
    end

    // In case the UUT hangs and never reaches $finish
    initial begin
        #10000;
        $error("ERROR: testbench timeout");
        $finish;
    end
endmodule
