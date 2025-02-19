# Matrix-Vector Multiplication Module

Please refer to the [ECE554-Minilab1.pdf](ECE554-Minilab1.pdf) for the complete project overview

## Project Overview
This project involves designing, simulating, and debugging a matrix-vector multiplication module using Hardware Description Language (HDL). The goal is to validate the design at different levels and implement it on an FPGA.

## Design Description
- **Example Design**: Matrix-vector multiplication.
- **Components**:
  - 8 MAC (Multiply-Accumulate) units.
  - FIFO (First In, First Out) for inputs A and B.
  - Enable (En) and Clear (Clr) signals for MAC operations.

## Part 1
### Part 1a: Design and Simulation
- Complete the design and simulate it with a testbench.
- A memory module with a partial implementation of the Intel Avalon MM slave interface is provided.
- Design a module that fetches data from the memory module to fill the FIFOs.
- The testbench should print all interface signals, states, and output signals.

### Part 1b: Timing Constraints
- Change the clock period in the Synopsys Design Constraint (.sdc) file to 200 MHz.
- Synthesize the design again and check if it meets the timing requirements using the Timing Analyzer.

## Part 2
### Part 2a: On-Board Testing
- Use LEDs to display and track the states of the top-level state machine.
- Show MAC outputs on 7-segment displays.

### Part 2b: SignalTap Verification
- Use SignalTap to ensure the correct implementation of the Avalon MM interface.

## Demo
- Simulate the working design.
- Verify timing analyzer reports.
- Test on-board functionality with LEDs, 7-segment displays, and SignalTap.
