.text
__reset:
mv sp, zero
lui sp, 0x40000
addi a0, zero, 10
sb a0, 0(sp)
