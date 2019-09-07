`ifndef CSR_ADDR
    `define CSR_ADDR 1
   
    `define MSR_MVENDORID  12'hF11
    `define MSR_MARCHID    12'hF12
    `define MSR_MIMPID     12'hF13
    `define MSR_MHARTID    12'hF14

    `define MSR_MSTATUS    12'h300
    `define MSR_MISA       12'h301
    `define MSR_MEDELEG    12'h302
    `define MSR_MIDELEG    12'h303
    `define MSR_MIE        12'h304
    `define MSR_MTVEC      12'h305
    `define MSR_MCOUNTEREN 12'h306

    `define MSR_MSCRATCH   12'h340
    `define MSR_MEPC       12'h341
    `define MSR_MCAUSE     12'h342
    `define MSR_MTVAL      12'h343
    `define MSR_MIP        12'h344
    `define MSR_MTAGS      12'h345
    `define MSR_MRND       12'h346

`endif
