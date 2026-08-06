.section .text
.globl _start

# Register usage:
# x1: base address of the 32-element array
# x2: outer-loop counter
# x3: inner-loop counter
# x4: address of the current array element
# x5: current array value
# x6: next array value
# x7: signed comparison result
# x8: completion magic value

_start:
    addi x1, x0, 0
    addi x2, x0, 31

outer_loop:
    addi x3, x2, 0
    addi x4, x1, 0

inner_loop:
    lw   x5, 0(x4)
    lw   x6, 4(x4)
    slt  x7, x6, x5
    beq  x7, x0, no_swap

    sw   x6, 0(x4)
    sw   x5, 4(x4)

no_swap:
    addi x4, x4, 4
    addi x3, x3, -1
    beq  x3, x0, end_inner
    jal  x0, inner_loop

end_inner:
    addi x2, x2, -1
    beq  x2, x0, sorting_done
    jal  x0, outer_loop

sorting_done:
    # Construct 0xCAFEBABE in x8.
    lui  x8, 0xCAFEC
    addi x8, x8, -1346

    # Write the completion magic value to DMEM address 0x80.
    sw   x8, 128(x0)

halt:
    jal  x0, halt
