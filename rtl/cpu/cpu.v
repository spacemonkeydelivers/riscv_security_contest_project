`include "cpu/alu.v"
`include "cpu/wb_bus.v"
`include "cpu/decoder.v"
`include "cpu/registers.v"


module cpu
    #(
        parameter VECTOR_RESET = 32'd0,
        parameter VECTOR_EXCEPTION = 32'd16
    )
    (
        input CLK_I,
	    input ACK_I,
	    input[31:0] DAT_I,
	    input RST_I,
        input TIMER_INTERRUPT_I,
        input TAGS_INTERRUPT_I,
	    output[31:0] ADR_O,
	    output[31:0] DAT_O,
       output[3:0] SEL_O,
	    output CYC_O,
	    output STB_O,
	    output WE_O,
       output check_tags_o,
       output clear_tag_mismatch_o
    );
   
    /*verilator public_module*/
    /*verilator no_inline_module*/

    wire interrupt_occured = TIMER_INTERRUPT_I || TAGS_INTERRUPT_I;
    wire clk, reset;
    assign clk = CLK_I;
    assign reset = RST_I;

    // MSRS
    reg[31:0] pc, pcnext;
    reg nextpc_from_alu, writeback_from_alu, writeback_from_bus;

    localparam CAUSE_INSTRUCTION_MISALIGNED = 32'h00000000;
    localparam CAUSE_EXTERNAL_INTERRUPT     = 32'h8000000b;
    localparam CAUSE_INVALID_INSTRUCTION    = 32'h00000002;
    localparam CAUSE_BREAK                  = 32'h00000003;
    localparam CAUSE_ECALL                  = 32'h0000000b;
    localparam CAUSE_TAG_MISMATCH           = 32'h0000000a;

    localparam VENDOR_ID                    = 32'hC001F001;

    // ALU instance
    reg alu_en = 0;
    reg[3:0] alu_op = 0;
    wire[31:0] alu_dataout;
    reg[31:0] alu_dataS1, alu_dataS2;
    wire alu_busy, alu_lt, alu_ltu, alu_eq;

    alu alu_inst(
        .I_clk(clk),
        .I_en(alu_en),
        .I_reset(reset),
        .I_dataS1(alu_dataS1),
        .I_dataS2(alu_dataS2),
        .I_aluop(alu_op),
        .O_busy(alu_busy),
        .O_data(alu_dataout),
        .O_lt(alu_lt),
        .O_ltu(alu_ltu),
        .O_eq(alu_eq)
    );
    
    reg bus_en = 0;
    reg[3:0] bus_op = 0;
    wire[31:0] bus_dataout;
    reg[31:0] bus_dataout_stored;
    reg[31:0] bus_addr;
    wire bus_busy;

    reg reg_we = 0, reg_re = 0;
    reg clear_tag_mismatch = 0;
    assign clear_tag_mismatch_o = clear_tag_mismatch;
    wire[31:0] reg_val1, reg_val2;
    reg[31:0] reg_datain;

    // Bus instance
    wb_cpu_bus bus_inst(
        .I_en(bus_en),
        .I_op(bus_op),
        .I_data(reg_val2),
        .I_addr(bus_addr),
        .O_data(bus_dataout),
        .O_busy(bus_busy),

        .CLK_I(clk),
	    .ACK_I(ACK_I),
	    .DAT_I(DAT_I),
       .SEL_O(SEL_O),
	    .RST_I(RST_I),
	    .ADR_O(ADR_O),
	    .DAT_O(DAT_O),
	    .CYC_O(CYC_O),
	    .STB_O(STB_O),
	    .WE_O(WE_O)
    );

    // Decoder instance
    wire[4:0] dec_rs1, dec_rs2, dec_rd;
    wire[31:0] dec_imm;
    wire[4:0] dec_opcode;
    wire[2:0] dec_funct3;
    wire[6:0] dec_funct7;
    wire[5:0] dec_branchmask;
    reg dec_en;

    decoder dec_inst(
        .I_clk(clk),
        .I_en(dec_en),
        .I_instr(bus_dataout_stored),
        .O_rs1(dec_rs1),
        .O_rs2(dec_rs2),
        .O_rd(dec_rd),
        .O_imm(dec_imm),
        .O_opcode(dec_opcode),
        .O_funct3(dec_funct3),
        .O_funct7(dec_funct7),
        .O_branchmask(dec_branchmask)
	);

    // Registers instance
    registers reg_inst(
        .I_clk(clk),
        .I_data(reg_datain),
        .I_rs1(dec_rs1),
        .I_rs2(dec_rs2),
        .I_rd(dec_rd),
        .I_re(reg_re),
        .I_we(reg_we),
        .O_regval1(reg_val1),
        .O_regval2(reg_val2)
    );

    // Muxer for first operand of ALU
    localparam MUX_ALUDAT1_REGVAL1 = 0;
    localparam MUX_ALUDAT1_PC      = 1;
    reg mux_alu_s1_sel = MUX_ALUDAT1_REGVAL1;
    always @(*) begin
        case(mux_alu_s1_sel)
            MUX_ALUDAT1_REGVAL1: alu_dataS1 = reg_val1;
            default:             alu_dataS1 = pc; // MUX_ALUDAT1_PC
        endcase
    end

    // Muxer for second operand of ALU
    localparam MUX_ALUDAT2_REGVAL2 = 0;
    localparam MUX_ALUDAT2_IMM     = 1;
    localparam MUX_ALUDAT2_INSTLEN = 2;
    reg[1:0] mux_alu_s2_sel = MUX_ALUDAT2_REGVAL2;
    always @(*) begin
        case(mux_alu_s2_sel)
            MUX_ALUDAT2_REGVAL2: alu_dataS2 = reg_val2;
            MUX_ALUDAT2_IMM:     alu_dataS2 = dec_imm;
            default:             alu_dataS2 = 4; // MUX_ALUDAT2_INSTLEN
        endcase
    end

    // Muxer for bus address
    localparam MUX_BUSADDR_ALU = 0;
    localparam MUX_BUSADDR_PC  = 1;
    reg mux_bus_addr_sel = MUX_BUSADDR_ALU;
    always @(*) begin
        case(mux_bus_addr_sel)
            MUX_BUSADDR_ALU: bus_addr = alu_dataout;
            default:         bus_addr = pc; // MUX_BUSADDR_PC
        endcase
    end

    // Muxer for MSRs
    wire[11:0] mux_msr_sel;
    reg[31:0] msr_data;
    assign mux_msr_sel = dec_imm[11:0];

    reg csr_exists;
    wire csr_ro;

    localparam MSR_MVENDORID = 12'hF11;
    localparam MSR_MARCHID   = 12'hF12;
    localparam MSR_MIMPID    = 12'hF13;
    localparam MSR_MHARTID   = 12'hF14;
    
    localparam MSR_MSTATUS    = 12'h300;
    localparam MSR_MISA       = 12'h301;
    localparam MSR_MEDELEG    = 12'h302;
    localparam MSR_MIDELEG    = 12'h303;
    localparam MSR_MIE        = 12'h304;
    localparam MSR_MTVEC      = 12'h305;
    localparam MSR_MCOUNTEREN = 12'h306;

    localparam MSR_MSCRATCH   = 12'h340;
    localparam MSR_MEPC       = 12'h341;
    localparam MSR_MCAUSE     = 12'h342;
    localparam MSR_MTVAL      = 12'h343;
    localparam MSR_MIP        = 12'h344;
    localparam MSR_MTAGS      = 12'h345;

    enum {
       M_VENDOR_ID = 0,
       M_ARCH_ID   = 1,
       M_IMP_ID    = 2,
       M_HART_ID   = 3,
       M_STATUS    = 4,
       M_ISA       = 5,
       M_EDEKEG    = 6,
       M_IDELEG    = 7,
       M_IE        = 8,
       M_TVEC      = 9,
       M_COUNTEREN = 10,
       M_SCRATCH   = 11,
       M_EPC       = 12,
       M_CAUSE     = 13,
       M_TVAL      = 14,
       M_IP        = 15,
       M_TAGS      = 16,
       M_LAST
    } 
    csr_names;
    
    reg [31:0] csr [0:16];
    reg [4:0]  csr_index;

    always @(*) begin
       case (mux_msr_sel)
          MSR_MVENDORID:  csr_index = M_VENDOR_ID;
          MSR_MARCHID:    csr_index = M_ARCH_ID;
          MSR_MIMPID:     csr_index = M_IMP_ID;
          MSR_MHARTID:    csr_index = M_HART_ID;
          MSR_MSTATUS:    csr_index = M_STATUS;
          MSR_MISA:       csr_index = M_ISA;
          MSR_MEDELEG:    csr_index = M_EDEKEG;
          MSR_MIDELEG:    csr_index = M_IDELEG;
          MSR_MIE:        csr_index = M_IE;
          MSR_MTVEC:      csr_index = M_TVEC;
          MSR_MCOUNTEREN: csr_index = M_COUNTEREN;
          MSR_MSCRATCH:   csr_index = M_SCRATCH;
          MSR_MEPC:       csr_index = M_EPC;
          MSR_MCAUSE:     csr_index = M_CAUSE;
          MSR_MTVAL:      csr_index = M_TVAL;
          MSR_MIP:        csr_index = M_IP;
          MSR_MTAGS:      csr_index = M_TAGS;
          default:        csr_index = M_LAST;
       endcase
    end

    always @(*) begin
        msr_data = csr[csr_index];
    end

    always @(*) begin
        case(mux_msr_sel)
            MSR_MVENDORID: csr_exists = 1;
            MSR_MARCHID:   csr_exists = 1;
            MSR_MIMPID:    csr_exists = 1;
            MSR_MHARTID:   csr_exists = 1;
            
            MSR_MSTATUS:   csr_exists = 1;
            MSR_MCAUSE:    csr_exists = 1;
            MSR_MEPC:      csr_exists = 1;
            MSR_MISA:      csr_exists = 1;
            MSR_MTVAL:     csr_exists = 1;

            MSR_MTVEC:     csr_exists = 1;
            MSR_MSCRATCH:  csr_exists = 1;
            MSR_MTAGS:     csr_exists = 1;
            default:       csr_exists = 0;
        endcase
    end
    assign csr_ro = (mux_msr_sel[11:10] == 2'b11) && ((`FUNC_CSRRW == dec_funct3) || (`FUNC_CSRRWI) == dec_funct3);

    // Muxer for register data input
    localparam MUX_REGINPUT_ALU = 0;
    localparam MUX_REGINPUT_BUS = 1;
    localparam MUX_REGINPUT_IMM = 2;
    localparam MUX_REGINPUT_MSR = 3;
    reg[1:0] mux_reg_input_sel = MUX_REGINPUT_ALU;
    always @(*) begin
        case(mux_reg_input_sel)
            MUX_REGINPUT_ALU: reg_datain = alu_dataout;
            MUX_REGINPUT_BUS: reg_datain = bus_dataout;
            MUX_REGINPUT_IMM: reg_datain = dec_imm;
            default:          reg_datain = msr_data; // MUX_REGINPUT_MSR
        endcase
    end

    localparam STATE_RESET          = 4'd0;
    localparam STATE_FETCH          = 4'd1;
    localparam STATE_DECODE         = 4'd2;
    localparam STATE_EXEC           = 4'd3;
    localparam STATE_STORE2         = 4'd5;
    localparam STATE_LOAD2          = 4'd6;
    localparam STATE_BRANCH2        = 4'd7;
    localparam STATE_TRAP1          = 4'd8;
    localparam STATE_SYSTEM         = 4'd9;
    localparam STATE_CSR1           = 4'd10;
    localparam STATE_CSR2           = 4'd11;


    reg[3:0] state, prevstate = STATE_RESET, nextstate = STATE_RESET;

    wire busy;
    assign busy = alu_busy | bus_busy;

    // evaluate branch conditions
    wire branch;
    assign branch = (dec_branchmask & {!alu_ltu, alu_ltu, !alu_lt, alu_lt, !alu_eq, alu_eq}) != 0;


    // only transition to new state if not busy    
    always @(negedge clk) begin
        state = busy ? prevstate : nextstate;
    end

    wire addr_misaligned = | (pc[1:0] & 2'b11);
    assign check_tags_o = csr[M_TAGS][0];

    reg [31:0] csr_to_write;
    always @(*) begin
      case (dec_funct3)
         `FUNC_CSRRW:   csr_to_write = (reg_val1);
         `FUNC_CSRRWI:  csr_to_write = ({27'b0, dec_rs1});
         `FUNC_CSRRS:   csr_to_write = (csr[csr_index] | reg_val1);
         `FUNC_CSRRSI:  csr_to_write = (csr[csr_index] | {27'b0, dec_rs1});
         `FUNC_CSRRC:   csr_to_write = (csr[csr_index] & ~reg_val1);
         `FUNC_CSRRCI:  csr_to_write = (csr[csr_index] & ~({27'b0, dec_rs1}));
         default:       csr_to_write = 0;
      endcase
    end

    always @(negedge clk) begin

        alu_en <= 0;
        bus_en <= 0;
        dec_en <= 0;
        reg_re <= 0;
        reg_we <= 0;

        clear_tag_mismatch <= 0;

        mux_alu_s1_sel <= MUX_ALUDAT1_REGVAL1;
        mux_alu_s2_sel <= MUX_ALUDAT2_REGVAL2;
        mux_reg_input_sel <= MUX_REGINPUT_ALU;

        alu_op <= `ALUOP_ADD;

        // remember currently active state to return to if busy
        prevstate <= state;

        case(state)
            STATE_RESET: begin
                pcnext <= VECTOR_RESET;
                csr[M_STATUS][3] <= 0; // disable machine-mode external interrupt
                csr[M_TAGS][0] <= 0;
                nextstate <= STATE_FETCH;
                csr[M_TVEC] <= VECTOR_EXCEPTION;
                csr[M_VENDOR_ID] <= VENDOR_ID;
                nextpc_from_alu <= 0;
                writeback_from_alu <= 0;
                writeback_from_bus <= 0;
                bus_dataout_stored <= 0;
            end

            STATE_FETCH: begin
                // write result of previous instruction to registers if requested
                mux_reg_input_sel <= writeback_from_alu ? MUX_REGINPUT_ALU : MUX_REGINPUT_BUS;
                reg_we <= writeback_from_alu | writeback_from_bus;
                writeback_from_alu <= 0;
                writeback_from_bus <= 0;

                // update PC
                pc <= nextpc_from_alu ? alu_dataout : pcnext;
                pc[0] <= 0;

                // fetch next instruction 
                bus_en <= 1;
                bus_op <= `BUSOP_READW;
                mux_bus_addr_sel <= MUX_BUSADDR_PC;
                if (addr_misaligned) begin
                   nextstate <= STATE_TRAP1;
                   csr[M_CAUSE] <= CAUSE_INSTRUCTION_MISALIGNED;
                end
                else begin
                   nextstate <= STATE_DECODE;
                end
            end

            STATE_DECODE: begin
                // assume for now the next PC will come from pcnext
                nextpc_from_alu <= 0;

                dec_en <= 1;
                nextstate <= STATE_EXEC;
                bus_dataout_stored <= bus_dataout;

                // read registers
                reg_re <= 1;

                // ALU is unused... let's compute PC+4!
                alu_en <= 1;
                mux_alu_s1_sel <= MUX_ALUDAT1_PC;
                mux_alu_s2_sel <= MUX_ALUDAT2_INSTLEN;

                // checking for interrupt here because no bus operations are active here
                // TODO: find a proper place that doesn't let an instruction fetch go to waste
                if (interrupt_occured && csr[M_STATUS][3]) begin
                    if (TAGS_INTERRUPT_I && csr[M_TAGS][0]) begin
                       csr[M_CAUSE] <= CAUSE_TAG_MISMATCH;
                    end
                    if (TIMER_INTERRUPT_I) begin
                       csr[M_CAUSE] <= CAUSE_EXTERNAL_INTERRUPT;
                    end
                    nextstate <= STATE_TRAP1;
                end

            end

            STATE_EXEC: begin
                // ALU output when coming from decode is PC+4... store it in pcnext
                if(!busy) pcnext <= alu_dataout;

                case(dec_opcode)
                    `OP_OP: begin
                        alu_en <= 1;
                        mux_alu_s1_sel <= MUX_ALUDAT1_REGVAL1;
                        mux_alu_s2_sel <= MUX_ALUDAT2_REGVAL2;
                        case(dec_funct3)
                            `FUNC_ADD_SUB:  alu_op <= dec_funct7[5] ? `ALUOP_SUB : `ALUOP_ADD;
                            `FUNC_SLL:      alu_op <= `ALUOP_SLL;
                            `FUNC_SLT:      alu_op <= `ALUOP_SLT;
                            `FUNC_SLTU:     alu_op <= `ALUOP_SLTU;
                            `FUNC_XOR:      alu_op <= `ALUOP_XOR;
                            `FUNC_SRL_SRA:  alu_op <= dec_funct7[5] ? `ALUOP_SRA : `ALUOP_SRL;
                            `FUNC_OR:       alu_op <= `ALUOP_OR;
                            `FUNC_AND:      alu_op <= `ALUOP_AND;
                            default:        alu_op <= `ALUOP_ADD;
                        endcase
                        // do register writeback in FETCH
                        writeback_from_alu <= 1;
                        nextstate <= STATE_FETCH;
                    end

                    `OP_OPIMM: begin
                        alu_en <= 1;
                        mux_alu_s1_sel <= MUX_ALUDAT1_REGVAL1;
                        mux_alu_s2_sel <= MUX_ALUDAT2_IMM;
                        case(dec_funct3)
                            `FUNC_ADDI:         alu_op <= `ALUOP_ADD;
                            `FUNC_SLLI:         alu_op <= `ALUOP_SLL;
                            `FUNC_SLTI:         alu_op <= `ALUOP_SLT;
                            `FUNC_SLTIU:        alu_op <= `ALUOP_SLTU;
                            `FUNC_XORI:         alu_op <= `ALUOP_XOR;
                            `FUNC_SRLI_SRAI:    alu_op <= dec_funct7[5] ? `ALUOP_SRA : `ALUOP_SRL;
                            `FUNC_ORI:          alu_op <= `ALUOP_OR;
                            `FUNC_ANDI:         alu_op <= `ALUOP_AND;
                            default:            alu_op <= `ALUOP_ADD;
                        endcase
                        // do register writeback in FETCH
                        writeback_from_alu <= 1;
                        nextstate <= STATE_FETCH;
                    end

                    `OP_LOAD: begin // compute load address on ALU
                        alu_en <= 1;
                        alu_op <= `ALUOP_ADD;
                        mux_alu_s1_sel <= MUX_ALUDAT1_REGVAL1;
                        mux_alu_s2_sel <= MUX_ALUDAT2_IMM;
                        nextstate <= STATE_LOAD2;
                    end

                    `OP_STORE:  begin // compute store address on ALU
                        alu_en <= 1;
                        alu_op <= `ALUOP_ADD;
                        mux_alu_s1_sel <= MUX_ALUDAT1_REGVAL1;
                        mux_alu_s2_sel <= MUX_ALUDAT2_IMM;
                        nextstate <= STATE_STORE2;
                    end

                    `OP_JAL, `OP_JALR: begin
                        // return address computed during decode, write to register
                        reg_we <= 1;
                        mux_reg_input_sel <= MUX_REGINPUT_ALU;

                        // compute jal/jalr address
                        alu_en <= 1;
                        alu_op <= `ALUOP_ADD;
                        mux_alu_s1_sel <= (dec_opcode[1]) ? MUX_ALUDAT1_PC : MUX_ALUDAT1_REGVAL1;
                        mux_alu_s2_sel <= MUX_ALUDAT2_IMM;

                        nextpc_from_alu <= 1;
                        nextstate <= STATE_FETCH;
                    end

                    `OP_BRANCH: begin // use ALU for comparisons
                        alu_en <= 1;
                        alu_op <= `ALUOP_ADD; // doesn't really matter
                        mux_alu_s1_sel <= MUX_ALUDAT1_REGVAL1;
                        mux_alu_s2_sel <= MUX_ALUDAT2_REGVAL2;
                        nextstate <= STATE_BRANCH2;
                    end

                    `OP_AUIPC: begin // compute PC + IMM on ALU
                        alu_en <= 1;
                        alu_op <= `ALUOP_ADD;
                        mux_alu_s1_sel <= MUX_ALUDAT1_PC;
                        mux_alu_s2_sel <= MUX_ALUDAT2_IMM;
                        // do register writeback in FETCH
                        writeback_from_alu <= 1;
                        nextstate <= STATE_FETCH;
                    end

                    `OP_LUI: begin
                        reg_we <= 1;
                        mux_reg_input_sel <= MUX_REGINPUT_IMM;
                        nextstate <= STATE_FETCH;
                    end

                    `OP_MISCMEM:    nextstate <= STATE_FETCH; // nop
                    `OP_SYSTEM:     nextstate <= STATE_SYSTEM;
                    default:        nextstate <= STATE_TRAP1;
                endcase
            end


            STATE_LOAD2: begin // load from computed address
                bus_en <= 1;
                mux_bus_addr_sel <= MUX_BUSADDR_ALU;
                case(dec_funct3)
                    `FUNC_LB:   bus_op <= `BUSOP_READB;
                    `FUNC_LH:   bus_op <= `BUSOP_READH;
                    `FUNC_LW:   bus_op <= `BUSOP_READW;
                    `FUNC_LBU:  bus_op <= `BUSOP_READBU;
                    `FUNC_LT:   bus_op <= `BUSOP_READT;
                    default:    bus_op <= `BUSOP_READHU; // FUNC_LHU
                endcase
                //nextstate <= STATE_REGWRITEBUS;
                writeback_from_bus <= 1;
                nextstate <= STATE_FETCH;
            end


            STATE_STORE2: begin // store to computed address
                bus_en <= 1;
                mux_bus_addr_sel <= MUX_BUSADDR_ALU;
                case(dec_funct3)
                    `FUNC_SB:   bus_op <= `BUSOP_WRITEB;
                    `FUNC_SH:   bus_op <= `BUSOP_WRITEH;
                    `FUNC_ST:   bus_op <= `BUSOP_WRITET;
                    default:    bus_op <= `BUSOP_WRITEW; // FUNC_SW
                endcase
                // advance to next instruction
                nextstate <= STATE_FETCH;
            end

            STATE_BRANCH2: begin
                // use idle ALU to compute PC+immediate - in case we branch
                alu_en <= 1;
                alu_op <= `ALUOP_ADD;
                mux_alu_s1_sel <= MUX_ALUDAT1_PC;
                mux_alu_s2_sel <= MUX_ALUDAT2_IMM;

                nextpc_from_alu <= branch;
                nextstate <= STATE_FETCH;
            end

            STATE_SYSTEM: begin
                nextstate <= STATE_TRAP1;
                case(dec_funct3)
                    `FUNC_ECALL_EBREAK: begin
                        // handle ecall, ebreak and mret here
                        case(dec_imm[11:0])
                            `SYSTEM_ECALL:  csr[M_CAUSE] <= CAUSE_ECALL;
                            `SYSTEM_EBREAK: csr[M_CAUSE] <= CAUSE_BREAK;
                            `SYSTEM_MRET: begin
                                csr[M_STATUS][3] <= csr[M_STATUS][7];
                                pcnext <= csr[M_EPC];
                                nextstate <= STATE_FETCH;
                            end
                            default: csr[M_CAUSE] <= CAUSE_INVALID_INSTRUCTION;
                        endcase
                    end

                    `FUNC_CSRRW: begin
                        // handle csrrw here
                        nextstate <= STATE_CSR1;
                    end

                    `FUNC_CSRRWI: begin
                        // handle csrrw here
                        nextstate <= STATE_CSR1;
                    end

                    `FUNC_CSRRSI: begin
                        nextstate <= STATE_CSR1;
                    end

                    `FUNC_CSRRS: begin
                        nextstate <= STATE_CSR1;
                    end

                    `FUNC_CSRRCI: begin
                        nextstate <= STATE_CSR1;
                    end

                    `FUNC_CSRRC: begin
                        nextstate <= STATE_CSR1;
                    end

                    // unsupported SYSTEM instruction
                    default: csr[M_CAUSE] <= CAUSE_INVALID_INSTRUCTION;
                endcase
            end

            STATE_TRAP1: begin
                csr[M_STATUS][7] <= csr[M_STATUS][3];
                csr[M_STATUS][3] <= 0;
                csr[M_EPC] <= pc;
                csr[M_TVAL] <= pc;
                pcnext <= csr[M_TVEC];
                nextpc_from_alu <= 0;
                nextstate <= STATE_FETCH;
            end

            STATE_CSR1: begin
                if (csr_exists) begin
                    // write MSR-value to register
                    mux_reg_input_sel <= MUX_REGINPUT_MSR;
                    reg_we <= 1;
                    nextstate <= STATE_CSR2;
                end else begin
                    nextstate <= STATE_TRAP1;
                end
            end

            STATE_CSR2: begin
                // update MSRs with value of rs1
                if(!dec_imm[11]) begin // denotes a writable non-standard machine-mode MSR
                    if (csr_index == M_TAGS) begin
                       csr[csr_index] <= csr_to_write & ~32'h00000002;
                       clear_tag_mismatch <= csr_to_write[1];
                    end
                    else begin
                       csr[csr_index] <= csr_to_write;
                    end
                end
                // advance to next instruction
                if (csr_ro) begin
                   nextstate <= STATE_TRAP1;
                end else begin
                   nextstate <= STATE_FETCH;
                end
            end
            
        endcase


        if(reset) begin
            prevstate <= STATE_RESET;
            nextstate <= STATE_RESET;
        end


    end



endmodule
