#include <defines.S>
#include <boot.S>

.text
main:
    mv sp, zero
    lui sp, 0x4000

    // Disable interrupts
    li t2, 0
    csrw mie, t2

    // Tick on every clock
    addi a0, zero, 1
    sw a0, 16(sp)

    // up to 1 clock, should interrupt
    // immediately after MIE wirte
    addi a0, zero, 1
    sb a0, 8(sp)

    // Enable interrupts
    li t2, 0x80
    csrw mie, t2

    mv zero, zero
    mv zero, zero
    mv zero, zero
    mv zero, zero
    mv zero, zero
    mv zero, zero
    lb a0, 0(sp)
    sb zero, 1(sp)
    mv zero, zero
    mv zero, zero
    mv zero, zero

    FAILED 1

ON_EXCEPTION:
    nop

check_mip_bit_set:
    csrr t0, mip
    andi t0, t0, 0x80
    bnez t0, check_mip_mtimecmp
    FAILED 2

check_mip_mtimecmp:
    mv sp, zero
    lui sp, 0x4000
    li t0, -1
    sw t0, 12(sp)

    // check MIP is zero
    csrr t0, mip
    andi t0, t0, 0x80
    beqz t0, looks_good
    FAILED 3

looks_good:
    sb a0, 8(sp)
    PASSED
