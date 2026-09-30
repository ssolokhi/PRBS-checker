`timescale 1ns/1ps
`default_nettype none

module data_serializer_tb ();
    localparam c_N_LANES = 2;
    logic tb_clock = 1'b0;
    always #5 tb_clock <= !tb_clock;
    logic tb_reset = 1'b1;

    logic [c_N_LANES-1:0] tb_parallel_data;
    logic tb_parallel_data_ready = 1'b0;
    logic tb_serial_data;
    logic tb_ready_for_new_data;

    data_serializer #(.c_N_LANES(c_N_LANES)) UUT (
        .i_clock(tb_clock),
        .i_reset(tb_reset),
        .i_parallel_data(tb_parallel_data),
        .i_parallel_data_ready(tb_parallel_data_ready),
        .o_serial_data(tb_serial_data),
        .o_ready_for_new_data(tb_ready_for_new_data)
    );

    initial begin
        $dumpfile("data_serializer_tb.vcd");
        $dumpvars(0, data_serializer_tb);
        // check reset (active-low!) to default seed value
        tb_reset <= 1'b0;
        repeat(5) @(posedge tb_clock) begin
            a_serial_data_resets: assert (tb_serial_data == 1'b0) 
            else $error("%0t: Serial data was not cleared upon reset", $time); 
        end
        tb_reset <= 1'b1;

        // check that words aren't loaded when input data not ready
        tb_parallel_data <= 'b11;
        @(posedge tb_clock);
        a_no_output_when_input_not_ready: assert (tb_serial_data == 1'b0) 
        else $error("%0t: Serial data has non-default value when inout data is not ready", $time); 

        // check that all possible 2-bit combinations are serialized correctly
        tb_parallel_data_ready <= 1'b1;
        for (int i = 0; i < 4; ++i) begin
            tb_parallel_data = i[1:0];
            @(posedge tb_clock);
            assert (tb_serial_data == tb_parallel_data[0]) 
            else $error("%0t: New word not serialized correctly: on 1st cycle expected %b, received %b", $time, tb_parallel_data[0], tb_serial_data); 
            @(posedge tb_clock);
            assert (tb_serial_data == tb_parallel_data[1]) 
            else $error("%0t: New word not serialized correctly: on 2nd cycle expected %b, received %b", $time, tb_parallel_data[1], tb_serial_data); 
        end

        $display("%0t: SUCCESS: all checks passed!", $time);
        $finish;
    end

    // In case the UUT hangs and never reaches $finish
    initial begin
        #1000;
        $error("ERROR: testbench timeout");
        $finish;
    end
endmodule
