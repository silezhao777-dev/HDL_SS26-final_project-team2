# HDL_SS26-final_project-team2
# PYNQ-Z2 Pipelined RISC-V Processor

## Project Overview

This project implements and verifies a five-stage pipelined RISC-V processor on the PYNQ-Z2 FPGA board.

The processor uses separate instruction and data BRAMs and is integrated into a Vivado Block Design as a custom IP. A Jupyter Notebook running on the ARM Processing System is used for hardware-in-the-loop verification.

The final system executes a RISC-V sorting program that sorts exactly 32 signed 32-bit integers in ascending order.

## Repository Contents

The repository contains:

- RISC-V processor RTL source files
- Simulation testbenches
- Vivado FPGA implementation files
- RISC-V sorting program and machine code
- PYNQ Jupyter verification script
- Project report and supporting documentation

## Verification

The design was verified using behavioural simulation and on-board testing on the PYNQ-Z2.

The Jupyter verification script loads the FPGA overlay and test data, controls the processor reset, waits for the completion flag `0xCAFEBABE`, reads the results from BRAM, and compares them with Python's `sorted()` output.

The final on-board test successfully sorted all 32 signed integers.

## Team

**Team 2**

- Jinghong Yang
- Sile Zhao

Course: Introduction to Hardware Design Languages and Tools (CITHN10001)  
Technical University of Munich
