module control_unit #(
    parameter N = 4
) (
    input clk,
    input reset,
    input start,
    output reg done,
    output reg load_enable,
    output reg pe_enable,
    output reg [31:0] cycle_counter
);
    localparam S_IDLE      = 3'b001;
    localparam S_LOADING   = 3'b010;
    localparam S_COMPUTING = 3'b100;

    reg [2:0] current_state, next_state;
    reg [31:0] counter;

    localparam LOADING_CYCLES = (2 * N) - 1;
    localparam COMPUTING_CYCLES = N;

    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_IDLE:      if (start) next_state = S_LOADING;
            S_LOADING:   if (counter == LOADING_CYCLES - 1) next_state = S_COMPUTING;
            S_COMPUTING: if (counter == COMPUTING_CYCLES - 1) next_state = S_IDLE;
            default:     next_state = S_IDLE;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S_IDLE;
            counter <= 0;
        end else begin
            current_state <= next_state;
            if ((current_state == S_IDLE && next_state == S_LOADING) ||
                (current_state == S_LOADING && next_state == S_COMPUTING)) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    always @(*) begin
        load_enable   = (current_state == S_LOADING);
        pe_enable     = (current_state == S_LOADING || current_state == S_COMPUTING);
        done          = (current_state == S_COMPUTING && counter == COMPUTING_CYCLES - 1);
        cycle_counter = counter;
    end

endmodule