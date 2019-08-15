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
        input INTERRUPT_I,
	    output[31:0] ADR_O,
	    output[31:0] DAT_O,
       output[3:0] SEL_O,
	    output CYC_O,
	    output STB_O,
	    output WE_O
    );
   
    /*verilator public_module*/
    /*verilator no_inline_module*/

    wire clk, reset;
    assign clk = CLK_I;
    assign reset = RST_I;

    // MSRS
    reg[31:0] pc, pcnext, epc;
    reg nextpc_from_alu, writeback_from_alu, writeback_from_bus;
    reg[31:0] evect = VECTOR_EXCEPTION;
     // current and previous machine-mode external interrupt enable
    reg meie = 0, meie_prev = 0;
     // machine cause register, mcause[4] denotes interrupt, mcause[3:0] encodes exception code
    reg[4:0] mcause = 0;

    localparam CAUSE_EXTERNAL_INTERRUPT     = 5'b11011;
    localparam CAUSE_INVALID_INSTRUCTION    = 5'b00010;
    localparam CAUSE_BREAK                  = 5'b00011;
    localparam CAUSE_ECALL                  = 5'b01011;

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
    reg[2:0] bus_op = 0;
    wire[31:0] bus_dataout;
    reg[31:0] bus_addr;
    wire bus_busy;

    reg reg_we = 0, reg_re = 0;
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
        .I_instr(bus_dataout),
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
    wire[31:0] mcause32;
    assign mcause32 = {mcause[4], {27{1'b0}}, mcause[3:0]};
    wire[31:0] mstatus32;
    assign mstatus32 = {{29{1'b0}}, INTERRUPT_I, meie_prev, meie};

    wire[31:0] vendor_id;
    assign vendor_id = 32'hC001_F001;
    wire[31:0] arch_id;
    assign arch_id = 32'hBAAD_A555;
    wire[31:0] imp_id;
    assign imp_id = 32'hC000_10FF;
    wire[31:0] hart_id;
    assign hart_id = 0;

    reg[31:0] scratch = 0;

    reg csr_exists;
    wire csr_ro;
    reg csr_source;

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

    always @(*) begin
        case(mux_msr_sel)
            MSR_MVENDORID: msr_data = vendor_id;
            MSR_MARCHID:   msr_data = arch_id;
            MSR_MIMPID:    msr_data = imp_id;
            MSR_MHARTID:   msr_data = hart_id;

            MSR_MSTATUS:   msr_data = mstatus32;
            MSR_MCAUSE:    msr_data = mcause32;
            MSR_MEPC:      msr_data = epc;

            MSR_MTVEC:     msr_data = evect;
            MSR_MSCRATCH:  msr_data = scratch;
            default:       msr_data = evect;
        endcase
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

            MSR_MTVEC:     csr_exists = 1;
            MSR_MSCRATCH:  csr_exists = 1;
            default:       csr_exists = 0;
        endcase
    end
    assign csr_ro = (mux_msr_sel[11:10] == 2'b11);

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

    localparam STATE_RESET          = 0;
    localparam STATE_FETCH          = 1;
    localparam STATE_DECODE         = 2;
    localparam STATE_EXEC           = 3;
    localparam STATE_STORE2         = 5;
    localparam STATE_LOAD2          = 6;
    localparam STATE_BRANCH2        = 7;
    localparam STATE_TRAP1          = 8;
    localparam STATE_SYSTEM         = 9;
    localparam STATE_CSRRW1         = 10;
    localparam STATE_CSRRW2         = 11;
    localparam STATE_CSRRS1         = 12;
    localparam STATE_CSRRS2         = 13;


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

    always @(negedge clk) begin

        alu_en <= 0;
        bus_en <= 0;
        dec_en <= 0;
        reg_re <= 0;
        reg_we <= 0;

        mux_alu_s1_sel <= MUX_ALUDAT1_REGVAL1;
        mux_alu_s2_sel <= MUX_ALUDAT2_REGVAL2;
        mux_reg_input_sel <= MUX_REGINPUT_ALU;

        alu_op <= `ALUOP_ADD;

        // remember currently active state to return to if busy
        prevstate <= state;

        case(state)
            STATE_RESET: begin
                pcnext <= VECTOR_RESET;
                meie <= 0; // disable machine-mode external interrupt
                nextstate <= STATE_FETCH;
                evect <= VECTOR_EXCEPTION;
                nextpc_from_alu <= 0;
                writeback_from_alu <= 0;
                writeback_from_bus <= 0;
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
                nextstate <= STATE_DECODE;
            end

            STATE_DECODE: begin
                // assume for now the next PC will come from pcnext
                nextpc_from_alu <= 0;

                dec_en <= 1;
                nextstate <= STATE_EXEC;

                // read registers
                reg_re <= 1;

                // ALU is unused... let's compute PC+4!
                alu_en <= 1;
                mux_alu_s1_sel <= MUX_ALUDAT1_PC;
                mux_alu_s2_sel <= MUX_ALUDAT2_INSTLEN;

                // checking for interrupt here because no bus operations are active here
                // TODO: find a proper place that doesn't let an instruction fetch go to waste
                if(meie & INTERRUPT_I) begin
                    mcause <= CAUSE_EXTERNAL_INTERRUPT;
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
                            `SYSTEM_ECALL: mcause <= CAUSE_ECALL;
                            `SYSTEM_EBREAK: mcause <= CAUSE_BREAK;
                            `SYSTEM_MRET: begin
                                meie <= meie_prev;
                                pcnext <= epc;
                                mcause <= 0;
                                nextstate <= STATE_FETCH;
                            end
                            default: mcause <= CAUSE_INVALID_INSTRUCTION;
                        endcase
                    end

                    `FUNC_CSRRW: begin
                        // handle csrrw here
                        nextstate <= STATE_CSRRW1;
                        csr_source = 1;
                    end

                    `FUNC_CSRRWI: begin
                        // handle csrrw here
                        nextstate <= STATE_CSRRW1;
                        csr_source = 0;
                    end

                    `FUNC_CSRRSI: begin
                        nextstate <= STATE_CSRRS1;
                        csr_source = 0;
                    end

                    `FUNC_CSRRS: begin
                        nextstate <= STATE_CSRRS1;
                        csr_source = 1;
                    end

                    // unsupported SYSTEM instruction
                    default: mcause <= CAUSE_INVALID_INSTRUCTION;
                endcase
            end

            STATE_TRAP1: begin
                meie_prev <= meie;
                meie <= 0;
                epc <= pc;
                pcnext <= evect;

                nextstate <= STATE_FETCH;
            end

            STATE_CSRRW1: begin
                if (csr_exists) begin
                    // write MSR-value to register
                    mux_reg_input_sel <= MUX_REGINPUT_MSR;
                    reg_we <= 1;
                    nextstate <= STATE_CSRRW2;
                end else begin
                    nextstate <= STATE_TRAP1;
                end
            end

            STATE_CSRRW2: begin
                // update MSRs with value of rs1
                if(!dec_imm[11]) begin // denotes a writable non-standard machine-mode MSR
                    case(dec_imm[11:0])
                        MSR_MCAUSE: mcause <= {reg_val1[31], reg_val1[3:0]};
                        MSR_MEPC:   epc <= reg_val1;
                        MSR_MSTATUS: begin
                            meie <= csr_source ? reg_val1[0] : dec_rs1;
                            meie_prev <= csr_source ? reg_val1[1] : dec_rs1;
                        end
                        MSR_MTVEC: evect <= reg_val1;
                        MSR_MSCRATCH: scratch <= csr_source ? reg_val1 : {27'b0, dec_rs1};
                    endcase
                end
                // advance to next instruction
                if (csr_ro) begin
                   nextstate <= STATE_TRAP1;
                end else begin
                   nextstate <= STATE_FETCH;
                end
            end
            
            STATE_CSRRS1: begin
                if (csr_exists) begin
                   nextstate <= STATE_CSRRS2;
                   mux_reg_input_sel <= MUX_REGINPUT_MSR;
                   reg_we <= 1;
                end 
                else begin
                   nextstate <= STATE_TRAP1;
                   mcause <= CAUSE_INVALID_INSTRUCTION;
                end
            end

            STATE_CSRRS2: begin
                if (csr_exists) begin
                   if(!dec_imm[11]) begin // denotes a writable non-standard machine-mode MSR
                      case(dec_imm[11:0])
                         MSR_MEPC:   epc <= epc | reg_val1;
                         MSR_MTVEC: evect <= evect | reg_val1;
                         MSR_MSCRATCH: scratch <= scratch | (csr_source ? reg_val1 : {27'b0, dec_rs1});
                      endcase
                   end
                end 
                nextstate <= STATE_FETCH;
            end

        endcase


        if(reset) begin
            prevstate <= STATE_RESET;
            nextstate <= STATE_RESET;
        end


    end



endmodule
