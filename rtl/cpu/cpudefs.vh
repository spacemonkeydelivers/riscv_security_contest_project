`ifndef CPUDEFS
    `define CPUDEFS 1

    // Muxer for first operand of ALU
    `define MUX_ALUDAT1_REGVAL1 1'd0
    `define MUX_ALUDAT1_PC      1'd1

    // Muxer for second operand of ALU
    `define MUX_ALUDAT2_REGVAL2    2'd0
    `define MUX_ALUDAT2_IMM        2'd1
    `define MUX_ALUDAT2_INSTLEN32  2'd2
    `define MUX_ALUDAT2_INSTLEN16  2'd3

    // Muxer for bus address
    `define MUX_BUSADDR_ALU  1'd0
    `define MUX_BUSADDR_PC   1'd1
    
    // Muxer for register data input
    `define MUX_REGINPUT_ALU     2'd0
    `define MUX_REGINPUT_BUS     2'd1
    `define MUX_REGINPUT_IMM     2'd2
    `define MUX_REGINPUT_MSR     2'd3

    // Decoder-executor next stages
    `define EXEC_TO_FETCH  3'd0
    `define EXEC_TO_LOAD   3'd1
    `define EXEC_TO_STORE  3'd2
    `define EXEC_TO_BRANCH 3'd3
    `define EXEC_TO_SYSTEM 3'd4
    `define EXEC_TO_TRAP   3'd5
    `define EXEC_TO_DEAD   3'd6

`endif
