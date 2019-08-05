
.weak __cfg_initialize_io
.equ __cfg_initialize_io, 1


// NOTE: these to parameters must be in-sync with linker script
.weak  __cfg_app_stack_top
.equ __cfg_app_stack_top, 0x80000000
.weak __cfg_app_stack_size
.equ __cfg_app_stack_size, 4096

