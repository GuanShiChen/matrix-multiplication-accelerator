`timescale 1ns / 1ps

module matrix_accelerator_tb;

    localparam NUM_TEST = 5;

    localparam N = 4;
    localparam DATA_WIDTH = 16;
    localparam ACCUM_WIDTH = 40;
    localparam ADDR_WIDTH = 8;
    localparam CLK_PERIOD = 10;

    reg clk, reset, start, load_a_b;
    reg [ADDR_WIDTH-1:0] write_addr, read_addr;
    reg signed [DATA_WIDTH-1:0] write_data_a, write_data_b;
    wire signed [ACCUM_WIDTH-1:0] read_data_c;
    wire done;

    top_level_accelerator #(
        .N(N), .DATA_WIDTH(DATA_WIDTH), .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut (.*);

    logic signed [DATA_WIDTH-1:0] matrix_a [0:N-1][0:N-1];
    logic signed [DATA_WIDTH-1:0] matrix_b [0:N-1][0:N-1];
    logic signed [ACCUM_WIDTH-1:0] golden_c [0:N-1][0:N-1];

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        $display("--- Starting Matrix Accelerator TB ---");
    
        for (int i = 1; i <= NUM_TEST; i++) begin
            $display("\n--- Starting Test %0d ---", i);
            reset_dut();
            run_test(i);
            $display("--- Test %0d Finished ---", i);
        end
    
        $display("--- Simulation Finished ---");
        $finish;
    end

    task run_test(input int test_num);
        automatic int error_count;
        $display("\n[Test %0d] Running with randomized inputs...", test_num);
        randomize_inputs_and_calculate_golden();
        load_matrices_into_dut();
        
        $display("[Test %0d] Starting computation...", test_num);
        start <= 1; @(posedge clk); start <= 0;

        wait_for_done(test_num);
        verify_results(test_num, error_count);

        if (error_count == 0) $display("\n[SUCCESS] Test %0d PASSED!", test_num);
        else $display("\n[FAILURE] Test %0d FAILED with %0d mismatches.", test_num, error_count);
    endtask

    task reset_dut;
        $display("Resetting DUT...");
        reset <= 1; start <= 0; load_a_b <= 0;
        write_addr <= 0; write_data_a <= 0; write_data_b <= 0; read_addr <= 0;
        repeat(5) @(posedge clk);
        reset <= 0; @(posedge clk);
        $display("Reset complete.");
    endtask

    task randomize_inputs_and_calculate_golden;
        $display("Generating random matrices and golden reference...");
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                matrix_a[i][j] = $urandom_range(-100, 100);
                matrix_b[i][j] = $urandom_range(-100, 100);
            end
        end
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                golden_c[i][j] = 0;
                for (int k = 0; k < N; k++) begin
                    golden_c[i][j] += matrix_a[i][k] * matrix_b[k][j];
                end
            end
        end
    endtask

    task load_matrices_into_dut;
        $display("Loading matrices into DUT memory...");
        load_a_b <= 1;
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                write_addr <= i * N + j;
                write_data_a <= matrix_a[i][j];
                write_data_b <= matrix_b[i][j];
                @(posedge clk);
            end
        end
        load_a_b <= 0; write_addr <= 0;
        $display("Loading complete.");
    endtask
    
    task wait_for_done(input int test_num);
        automatic int timeout_cycles = (3 * N) + 10;
        $display("[Test %0d] Waiting for 'done' signal...", test_num);
        repeat(timeout_cycles) begin
            if (done) begin
                $display("[Test %0d] 'done' signal received at time %0t.", test_num, $time);
                return;
            end
            @(posedge clk);
        end
        $error("[Test %0d] TIMEOUT: 'done' was not asserted.", test_num);
        $finish;
    endtask

    task automatic verify_results(input int test_num, output int mismatches);
        int local_mismatches = 0;
        logic signed [ACCUM_WIDTH-1:0] dut_result;
        $display("\n[Test %0d] Verifying results...", test_num);
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                read_addr <= i * N + j;
                @(posedge clk);
                @(posedge clk);
                dut_result = read_data_c;
                if (dut_result !== golden_c[i][j]) begin
                    local_mismatches++;
                    $display("  FAIL C[%0d][%0d]: Golden=%d, DUT=%d", i, j, golden_c[i][j], dut_result);
                end
            end
        end
        if (local_mismatches == 0) $display("All results match the golden model.");
        else $display("Found %0d mismatches.", local_mismatches);
        mismatches = local_mismatches;
    endtask

endmodule