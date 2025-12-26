# SPI-Design-With-UVM-Verification
Designed and verified an SPI master–slave protocol in SystemVerilog using a reusable UVM testbench supporting all four SPI modes.

Features:
-Supports SPI modes (write_data,read_data,write_error,read_error,write_read)
-Parameterized data width (8/16 bits)
-Constrained-random stimulus
-Scoreboard-based data checking
-Directed and random testcases

Verification Architecture:
-SPI Agent (Driver, Sequencer, Monitor)
-Scoreboard for data comparison
-Reusable UVM componentsVerification Architecture
-SPI Agent (Driver, Sequencer, Monitor)
-Scoreboard for data comparison
-Reusable UVM components

Results:
-All tests passed
-No data mismatches observed
-Functional correctness verified

Tools Used:
-SystemVerilog
-UVM
-EDA Playground
-Vivado
