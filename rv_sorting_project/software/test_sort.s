.section .text
.globl _start

# Sort 32 signed 32-bit integers in ascending order using bubble sort.
# The array is stored in DMEM from address 0x00 to 0x7C.
# After sorting, the processor writes 0xCAFEBABE to address 0x80
# to indicate that execution has completed successfully.

# Register usage:
# x1: Base address of the 32-element array.
# x2: Number of remaining outer-loop passes.
# x3: Number of comparisons in the current pass.
# x4: Address of the current array element.
# x5: Current array value.
# x6: Next array value.
# x7: Signed comparison result.
# x8: Completion magic value.

_start:
    # The array starts at DMEM address 0x00.
    addi x1, x0, 0

    # A 32-element bubble sort requires at most 31 passes.
    addi x2, x0, 31

outer_loop:
    # The number of comparisons decreases after each pass because
    # the largest remaining value has already moved to the end.
    addi x3, x2, 0

    # Restart from the beginning of the array for each outer pass.
    addi x4, x1, 0

inner_loop:
    # Load two adjacent signed 32-bit values.
    lw   x5, 0(x4)
    lw   x6, 4(x4)

    # Compare the values as signed integers.
    # x7 becomes 1 when x6 is smaller than x5.
    slt  x7, x6, x5

    # Keep the current order when x5 <= x6.
    beq  x7, x0, no_swap

    # Swap the adjacent values when x6 < x5.
    sw   x6, 0(x4)
    sw   x5, 4(x4)

no_swap:
    # Advance to the next pair of adjacent array elements.
    addi x4, x4, 4

    # Decrement the number of comparisons remaining in this pass.
    addi x3, x3, -1

    # Finish the current pass when all required pairs were checked.
    beq  x3, x0, end_inner

    # Continue the inner loop.
    jal  x0, inner_loop

end_inner:
    # One complete bubble-sort pass has finished.
    addi x2, x2, -1

    # Stop after all 31 passes have completed.
    beq  x2, x0, sorting_done

    # Start the next outer-loop pass.
    jal  x0, outer_loop

sorting_done:
    # Construct the 32-bit completion value 0xCAFEBABE.
    # LUI creates 0xCAFEC000, and ADDI adds -1346
    # to produce the final value 0xCAFEBABE.
    lui  x8, 0xCAFEC
    addi x8, x8, -1346

    # Write the completion magic value to DMEM address 0x80.
    # The Python verification script waits for this value before
    # reading and checking the sorted array.
    sw   x8, 128(x0)

halt:
    # Remain here after completion so that no further memory
    # locations or processor state are modified.
    jal  x0, halt
