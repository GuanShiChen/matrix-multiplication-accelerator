module systolic_array #(
    parameter N = 4,
    parameter DATA_WIDTH = 16,
    parameter ACCUM_WIDTH = 40
) (
    input clk,
    input reset,
    input pe_enable,

    input signed [N*DATA_WIDTH-1:0] array_in_a_flat,
    input signed [N*DATA_WIDTH-1:0] array_in_b_flat,

    output signed [N*N*ACCUM_WIDTH-1:0] result_c_flat
);

    wire signed [DATA_WIDTH-1:0] array_in_a [0:N-1];
    wire signed [DATA_WIDTH-1:0] array_in_b [0:N-1];
    wire signed [ACCUM_WIDTH-1:0] result_c [0:N-1][0:N-1];

    wire signed [DATA_WIDTH-1:0] a_wires [0:N-1][0:N];
    wire signed [DATA_WIDTH-1:0] b_wires [0:N][0:N-1];

    genvar i, j;
    generate
        // Unpack flattened array into 2D arrays
        for (i = 0; i < N; i = i + 1) begin : unpack_inputs
            assign array_in_a[i] = array_in_a_flat[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
            assign array_in_b[i] = array_in_b_flat[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
        end

        // Pack 2D result into a flattened output vector
        for (i = 0; i < N; i = i + 1) begin : pack_outputs_rows
            for (j = 0; j < N; j = j + 1) begin : pack_outputs_cols
                assign result_c_flat[((i*N+j)+1)*ACCUM_WIDTH-1 -: ACCUM_WIDTH] = result_c[i][j];
            end
        end
    endgenerate

    // Connect array inputs to the first row/column of PEs
    genvar k;
    for (k = 0; k < N; k = k + 1) begin : assign_inputs
        assign a_wires[k][0] = array_in_a[k];
        assign b_wires[0][k] = array_in_b[k];
    end

    // Generate the NxN array of PEs
    genvar row, col;
    generate
        for (row = 0; row < N; row = row + 1) begin : pe_rows
            for (col = 0; col < N; col = col + 1) begin : pe_cols
                processing_element #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACCUM_WIDTH(ACCUM_WIDTH)
                ) pe_inst (
                    .clk(clk),
                    .reset(reset),
                    .pe_enable(pe_enable),
                    .data_in_a(a_wires[row][col]),
                    .data_in_b(b_wires[row][col]),
                    .data_out_a(a_wires[row][col+1]),
                    .data_out_b(b_wires[row+1][col]),
                    .accum_out(result_c[row][col])
                );
            end
        end
    endgenerate

endmodule