module top_level_accelerator #(
    parameter N = 4,
    parameter DATA_WIDTH = 16,
    parameter ACCUM_WIDTH = 40
) (
    input clk,
    input reset,
    input start,
    input load_a_b,
    input [7:0] write_addr,
    input signed [DATA_WIDTH-1:0] write_data_a,
    input signed [DATA_WIDTH-1:0] write_data_b,
    input [7:0] read_addr,
    output signed [ACCUM_WIDTH-1:0] read_data_c,
    output done
);

    reg signed [DATA_WIDTH-1:0] mem_a [0:N-1][0:N-1];
    reg signed [DATA_WIDTH-1:0] mem_b [0:N-1][0:N-1];

    wire signed [DATA_WIDTH-1:0] array_in_a [0:N-1];
    wire signed [DATA_WIDTH-1:0] array_in_b [0:N-1];
    wire signed [ACCUM_WIDTH-1:0] result_c [0:N-1][0:N-1];

    wire signed [N*DATA_WIDTH-1:0] array_in_a_flat;
    wire signed [N*DATA_WIDTH-1:0] array_in_b_flat;
    wire signed [N*N*ACCUM_WIDTH-1:0] result_c_flat;

    wire load_enable, pe_enable, pe_reset;
    wire [31:0] cycle_counter;

    control_unit #(.N(N)) ctrl_inst (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done(done),
        .load_enable(load_enable),
        .pe_enable(pe_enable),
        .cycle_counter(cycle_counter)
    );

    assign pe_reset = reset || start;

    systolic_array #(.N(N), .DATA_WIDTH(DATA_WIDTH), .ACCUM_WIDTH(ACCUM_WIDTH)) sa_inst (
        .clk(clk), .reset(pe_reset), .pe_enable(pe_enable),
        .array_in_a_flat(array_in_a_flat),
        .array_in_b_flat(array_in_b_flat),
        .result_c_flat(result_c_flat)
    );

    always @(posedge clk) begin
        if (load_a_b) begin
            mem_a[write_addr / N][write_addr % N] <= write_data_a;
            mem_b[write_addr / N][write_addr % N] <= write_data_b;
        end
    end
    assign read_data_c = result_c[read_addr / N][read_addr % N];

    genvar row_s, col_s;
    generate
        for (row_s = 0; row_s < N; row_s = row_s + 1) begin : a_input_gen
            reg signed [DATA_WIDTH-1:0] a_input_reg;
            always @(posedge clk) begin
                if (load_enable && cycle_counter >= row_s && cycle_counter < (row_s + N))
                    a_input_reg <= mem_a[row_s][cycle_counter - row_s];
                else a_input_reg <= 0;
            end
            assign array_in_a[row_s] = a_input_reg;
        end

        for (col_s = 0; col_s < N; col_s = col_s + 1) begin : b_input_gen
            reg signed [DATA_WIDTH-1:0] b_input_reg;
             always @(posedge clk) begin
                if (load_enable && cycle_counter >= col_s && cycle_counter < (col_s + N))
                    b_input_reg <= mem_b[cycle_counter - col_s][col_s];
                else b_input_reg <= 0;
            end
            assign array_in_b[col_s] = b_input_reg;
        end
    endgenerate

    genvar i, j;
    generate
        for (i = 0; i < N; i = i + 1) begin : pack_inputs
            assign array_in_a_flat[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH] = array_in_a[i];
            assign array_in_b_flat[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH] = array_in_b[i];
        end

        for (i = 0; i < N; i = i + 1) begin : unpack_outputs_rows
            for (j = 0; j < N; j = j + 1) begin : unpack_outputs_cols
                assign result_c[i][j] = result_c_flat[((i*N+j)+1)*ACCUM_WIDTH-1 -: ACCUM_WIDTH];
            end
        end
    endgenerate

endmodule