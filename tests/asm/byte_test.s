.text
__reset:
addi a0, zero, 0x55
addi sp, zero, 0x100
sb a0, 0(sp)
sb a0, 1(sp)
sb a0, 2(sp)
sb a0, 3(sp)
