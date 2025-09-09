# Matrix Multiplication Accelerator


## Overview
The project implements a 2D matrix multiplication accelerator based on a systolic array architecture. The module design is written in Verilog, and verification testbenches are written in SystemVerilog.

The project takes inspiration from implementing Tensor Procecssing Units (TPUs) found in Google's AI accelerators and Tensor cores found in Nvidia's GPUs for high-performance computing and AI.


## Implementation Features

* **Systolic Array Architecture:** A 2D grid of Processing Elements (PEs) can perform parallel multiply-accumulate (MAC) operations.

* **Parameterized Design:** The matrix size ($N \times N$), data width, and accumulator width are fully customizable parameters, allowing the design to be adapted for various applications.

* **Comprehensive Testbench:** The testbench (`matrix_accelerator_tb.sv`) automates the verification process with random generated input matrices, calculating the expected results, and comparing the DUT's output against it.


## Module Hierarchy

### Modules:
```
top_level_accelerator.v
├── control_unit.v
└── systolic_array.v
    └── processing_element.v
```

- **`top_level_accelerator.v`**  
  The main integration module; connects the control logic, systolic array, and memory interfaces.

- **`control_unit.v`**  
  A finite state machine that manages the timing of loading, computation, and completion.

- **`systolic_array.v`**  
  Instantiates a 2D grid of `processing_element` modules and handles data flow.

- **`processing_element.v`**  
  The core MAC unit performing multiply-accumulate operations within the systolic array.

### Testbenches:

```
testbenches/
├── simple_matrix_accelerator_tb.sv
└── matrix_accelerator_tb.sv
```

  - `simple_matrix_accelerator_tb.sv`: A basic testbench demonstrating a single matrix multiplication using pre-defined input matrices. The resulting matrix is printed to the console for visual inspection.

  - `matrix_accelerator_tb.sv`: A comprehensive, self-checking testbench. Performs multiple tests with randomized input matrices and verifies the results against a calculated "golden" reference model.


