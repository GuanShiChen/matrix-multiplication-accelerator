module processing_element #(
    parameter DATA_WIDTH = 16,
    parameter ACCUM_WIDTH = 40
) (
    input clk,
    input reset,
    input pe_enable,

    input signed [DATA_WIDTH-1:0] data_in_a,
    input signed [DATA_WIDTH-1:0] data_in_b,

    output reg signed [DATA_WIDTH-1:0] data_out_a,
    output reg signed [DATA_WIDTH-1:0] data_out_b,
    output [ACCUM_WIDTH-1:0] accum_out
);

    reg signed [ACCUM_WIDTH-1:0] accum_reg;
    wire signed [(2*DATA_WIDTH)-1:0] product;

    assign product = data_in_a * data_in_b;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            accum_reg <= 0;
        end else if (pe_enable) begin
            accum_reg <= accum_reg + product;
        end
    end

    always @(posedge clk) begin
        data_out_a <= data_in_a;
        data_out_b <= data_in_b;
    end

    assign accum_out = accum_reg;

endmodule