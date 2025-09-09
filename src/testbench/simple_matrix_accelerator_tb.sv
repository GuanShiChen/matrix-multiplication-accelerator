`timescale 1ns/1ps

module simple_matrix_accelerator_tb;

    localparam N           = 4;
    localparam DATA_WIDTH  = 16;
    localparam ACCUM_WIDTH = 40;

    reg clk;
    reg reset;
    reg start;
    reg load_a_b;
    reg [7:0] write_addr;
    reg signed [DATA_WIDTH-1:0] write_data_a;
    reg signed [DATA_WIDTH-1:0] write_data_b;
    reg [7:0] read_addr;
    wire signed [ACCUM_WIDTH-1:0] read_data_c;
    wire done;

    top_level_accelerator #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .load_a_b(load_a_b),
        .write_addr(write_addr),
        .write_data_a(write_data_a),
        .write_data_b(write_data_b),
        .read_addr(read_addr),
        .read_data_c(read_data_c),
        .done(done)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    reg signed [DATA_WIDTH-1:0] matrix_a [0:N*N-1];
    reg signed [DATA_WIDTH-1:0] matrix_b [0:N*N-1];

    integer i;

    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        load_a_b = 0;
        write_addr = 0;
        write_data_a = 0;
        write_data_b = 0;
        read_addr = 0;

        for (i = 0; i < N*N; i = i + 1) begin
            matrix_a[i] = i;
            matrix_b[i] = i;
        end

        #20 reset = 0;

        for (i = 0; i < N*N; i = i + 1) begin
            @(posedge clk);
            write_addr   = i;
            write_data_a = matrix_a[i];
            write_data_b = matrix_b[i];
            load_a_b     = 1;
        end
        @(posedge clk);
        load_a_b = 0;

        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait(done);

        $display("=== Result Matrix C ===");
        for (i = 0; i < N*N; i = i + 1) begin
            @(posedge clk);
            read_addr = i;
            @(posedge clk);
            $display("C[%0d][%0d] = %0d", i/N, i%N, read_data_c);
        end

        $display("=== Simulation Complete ===");
        $stop;
    end

endmodule
