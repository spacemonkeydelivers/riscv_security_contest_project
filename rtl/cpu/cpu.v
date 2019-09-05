`include "cpu/alu.v"
`include "cpu/wb_cpu_bus.v"
`include "cpu/decoder.v"
`include "cpu/registers.v"
`include "cpu/lfsr_rnd.v"
`include "cpu/cpudefs.vh"

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
   
   reg [31:0] bus_dataout_stored;

    wire interrupt_occured = TIMER_INTERRUPT_I || TAGS_INTERRUPT_I;
    wire clk, reset;
    assign clk = CLK_I;
    assign reset = RST_I;

    // MSRS
    reg nextpc_from_alu, writeback_from_alu, writeback_from_bus;

    localparam CAUSE_INSTRUCTION_MISALIGNED = 32'h00000000;
    localparam CAUSE_INVALID_INSTRUCTION    = 32'h00000002;
    localparam CAUSE_BREAK                  = 32'h00000003;
    localparam CAUSE_ECALL                  = 32'h0000000b;
    localparam CAUSE_EXTERNAL_INTERRUPT     = 32'h8000000b;
    localparam CAUSE_TAG_MISMATCH           = 32'h80000010;

    // RND instance
    wire[31:0] rnd_data;

    lfsr_rnd lfsr_rnd_inst(
        .I_clk(clk),
        .I_reset(reset),
        .O_rnd(rnd_data)
    );

    // ALU instance
    reg alu_en = 0;
    wire [4:0] alu_op_final;
    reg[4:0] alu_op = 0;
    assign alu_op_final = (state == STATE_EXEC) ? dec_alu_oper : alu_op;

    wire[31:0] alu_dataout;
    reg[31:0] alu_dataS1, alu_dataS2;
    wire alu_busy, alu_lt, alu_ltu, alu_eq;

    alu alu_inst(
        .I_clk(clk),
        .I_en(alu_en),
        .I_reset(reset),
        .I_dataS1(alu_dataS1),
        .I_dataS2(alu_dataS2),
        .I_aluop(alu_op_final),
        .O_busy(alu_busy),
        .O_data(alu_dataout),
        .O_lt(alu_lt),
        .O_ltu(alu_ltu),
        .O_eq(alu_eq)
    );

    reg bus_en = 0;
    reg next_bus_en;

    reg[3:0] bus_op = 0;
    wire[31:0] bus_dataout;
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
    wire[5:0] dec_branchmask;
    reg dec_en;

    wire [4:0] dec_alu_oper;
    wire exec_mux_alu_s1_sel;
    wire [1:0] exec_mux_alu_s2_sel;
    wire [2:0] exec_next_stage;
    wire exec_writeback_from_alu;
    wire exec_writeback_from_imm;
    wire exec_next_pc_from_alu;
    wire [1:0] exec_mux_reg_input_sel;
    wire [2:0] dec_funct3;
    wire write_reg;

    decoder dec_inst(
        .I_clk(clk),
        .I_en(dec_en),
        .I_instr(bus_dataout_stored),
        .O_rs1(dec_rs1),
        .O_rs2(dec_rs2),
        .O_rd(dec_rd),
        .O_imm(dec_imm),
        .O_branchmask(dec_branchmask),
        .alu_oper_o(dec_alu_oper),
        .exec_mux_alu_s1_sel_o(exec_mux_alu_s1_sel),
        .exec_mux_alu_s2_sel_o(exec_mux_alu_s2_sel),
        .exec_next_stage_o(exec_next_stage),
        .exec_writeback_from_alu_o(exec_writeback_from_alu),
        .exec_writeback_from_imm_o(exec_writeback_from_imm),
        .exec_next_pc_from_alu_o(exec_next_pc_from_alu),
        .exec_mux_reg_input_sel_o(exec_mux_reg_input_sel),
        .funct3_o(dec_funct3),
        .write_reg_o(write_reg)
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

    wire mux_alu_s1_sel_f;
    reg mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
    assign mux_alu_s1_sel_f = (state == STATE_EXEC) ? exec_mux_alu_s1_sel : mux_alu_s1_sel;
    always @(*) begin
        case(mux_alu_s1_sel_f)
            `MUX_ALUDAT1_REGVAL1: alu_dataS1 = reg_val1;
            default:             alu_dataS1 = pc; // MUX_ALUDAT1_PC
        endcase
    end

    wire [1:0] mux_alu_s2_sel_f;
    reg[1:0] mux_alu_s2_sel = `MUX_ALUDAT2_REGVAL2;
    assign mux_alu_s2_sel_f = (state == STATE_EXEC) ? exec_mux_alu_s2_sel : mux_alu_s2_sel;
    always @(*) begin
        case(mux_alu_s2_sel_f)
            `MUX_ALUDAT2_REGVAL2: alu_dataS2 = reg_val2;
            `MUX_ALUDAT2_IMM:     alu_dataS2 = dec_imm;
            default:             alu_dataS2 = 4; // MUX_ALUDAT2_INSTLEN
        endcase
    end

    reg mux_bus_addr_sel = `MUX_BUSADDR_ALU;
    always @(*) begin
        case(mux_bus_addr_sel)
            `MUX_BUSADDR_ALU: bus_addr = alu_dataout;
            default:         bus_addr = pc; // MUX_BUSADDR_PC
        endcase
    end

    // Muxer for MSRs
    wire [11:0] mux_msr_sel;
    wire [31:0] msr_data;
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
    localparam MSR_RND        = 12'h346;

    localparam [4:0] M_VENDOR_ID = 0,
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
                     M_RND       = 17,
                     M_LAST      = 18;

    reg [31:0] csr [0:17];
    reg [4:0]  csr_index;

    always @(*) begin
       case (mux_msr_sel)
          MSR_MVENDORID:  csr_index = M_VENDOR_ID;
          MSR_MHARTID:    csr_index = M_HART_ID;
          MSR_MSTATUS:    csr_index = M_STATUS;
          MSR_MISA:       csr_index = M_ISA;
          MSR_MIE:        csr_index = M_IE;
          MSR_MTVEC:      csr_index = M_TVEC;
          MSR_MCOUNTEREN: csr_index = M_COUNTEREN;
          MSR_MSCRATCH:   csr_index = M_SCRATCH;
          MSR_MEPC:       csr_index = M_EPC;
          MSR_MCAUSE:     csr_index = M_CAUSE;
          MSR_MTVAL:      csr_index = M_TVAL;
          MSR_MIP:        csr_index = M_IP;
          MSR_MTAGS:      csr_index = M_TAGS;
          MSR_RND:        csr_index = M_RND;
          default:        csr_index = M_LAST;
       endcase
    end

    assign csr[M_RND] = rnd_data;
    assign msr_data = csr[csr_index];

    always @(*) begin
        case(mux_msr_sel)
            MSR_MVENDORID: csr_exists = 1;
            MSR_MHARTID:   csr_exists = 1;

            MSR_MSTATUS:   csr_exists = 1;
            MSR_MCAUSE:    csr_exists = 1;
            MSR_MEPC:      csr_exists = 1;
            MSR_MISA:      csr_exists = 1;
            MSR_MTVAL:     csr_exists = 1;

            MSR_MTVEC:     csr_exists = 1;
            MSR_MSCRATCH:  csr_exists = 1;
            MSR_MTAGS:     csr_exists = 1;
            MSR_MIE:       csr_exists = 1;
            MSR_MIP:       csr_exists = 1;
            MSR_RND:       csr_exists = 1;
            default:       csr_exists = 0;
        endcase
    end
    assign csr_ro = 0;

    reg [1:0] mux_reg_input_sel = `MUX_REGINPUT_ALU;
    always @(*) begin
        case(mux_reg_input_sel)
            `MUX_REGINPUT_ALU:     reg_datain = alu_dataout;
            `MUX_REGINPUT_BUS:     reg_datain = bus_dataout;
            `MUX_REGINPUT_IMM:     reg_datain = dec_imm;
            `MUX_REGINPUT_MSR:     reg_datain = msr_data;
            default:               reg_datain = 32'hFFFFFFFF;
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
    localparam STATE_UPDATE_PC      = 4'd10;
    localparam STATE_CSR2           = 4'd11;
    localparam STATE_DEAD           = 4'd12;
    localparam STATE_PRE_FETCH      = 4'd13;
    localparam STATE_STORE1         = 4'd14;
    localparam STATE_LOAD1          = 4'd15;


    wire busy;
    assign busy = alu_busy | bus_busy;

    // evaluate branch conditions
    wire branch;
    assign branch = (dec_branchmask & {!alu_ltu, alu_ltu, !alu_lt, alu_lt, !alu_eq, alu_eq}) != 0;


   reg [3:0] state;
   reg [3:0] next_state;

   reg [31:0] pc;
   reg [31:0] next_pc;

   wire stall = bus_busy;
   reg update_pc;

   reg [31:0] pcnext;
   reg [31:0] next_pcnext;

   reg next_writeback_from_bus;

   reg branch_pc_from_alu;
   reg next_branch_pc_from_alu;

   always @ (posedge clk) begin
      if (reset) begin
         state <= STATE_RESET;
         pc <= (VECTOR_RESET);
         pcnext <= 0;
         writeback_from_bus <= 0;
         bus_dataout_stored <= 0;
         branch_pc_from_alu <= 0;
      end
      else begin
         state <= stall ? state : next_state;
//         pc <= (update_pc && !busy) ? next_pc : pc;
         pc <= (update_pc && !busy) ? next_pc : pc;
         pcnext <= ((state == STATE_DECODE) && !busy) ? next_pcnext : pcnext;
         writeback_from_bus <= (busy) ? writeback_from_bus : next_writeback_from_bus;
         bus_dataout_stored <= (state == STATE_FETCH) ? bus_dataout : bus_dataout_stored;
         branch_pc_from_alu <= next_branch_pc_from_alu;
      end
   end

   always @ (*) begin
      update_pc = 0;
      
      bus_en = 0;
      dec_en = 0;

      next_pcnext = 0;

      reg_we = 0;
      reg_re = 0;

      bus_op = `BUSOP_READW;
      mux_bus_addr_sel = `MUX_BUSADDR_ALU;
            
      writeback_from_alu = 0;
      next_writeback_from_bus = 0;
      next_pc = 0;

      mux_reg_input_sel = 0;
      next_branch_pc_from_alu = 0;
      case (state)
         STATE_RESET: begin
            next_state = STATE_PRE_FETCH;
         end
         STATE_UPDATE_PC: begin
            update_pc = 1;
            next_state = STATE_PRE_FETCH;
            next_pc = (exec_next_pc_from_alu || branch_pc_from_alu) ? alu_dataout : pcnext;
            mux_reg_input_sel = (writeback_from_alu || exec_writeback_from_alu) ? `MUX_REGINPUT_ALU :
                                (exec_writeback_from_imm                      ) ?  exec_mux_reg_input_sel :
                                                                                  `MUX_REGINPUT_BUS;
            reg_we = writeback_from_alu || writeback_from_bus || exec_writeback_from_imm || exec_writeback_from_alu;
         end
         STATE_PRE_FETCH: begin
            mux_bus_addr_sel = `MUX_BUSADDR_PC;
            next_state = STATE_FETCH;
            bus_en = 1;
            bus_op = `BUSOP_READW;
            
         end
         STATE_FETCH: begin
            next_state = STATE_DECODE;
            // ALU is unused... let's compute PC+4!
            alu_en = 1;
            mux_alu_s1_sel = `MUX_ALUDAT1_PC;
            mux_alu_s2_sel = `MUX_ALUDAT2_INSTLEN;
         end
         STATE_DECODE: begin
            dec_en = 1;
            reg_re = 1;
            next_state = STATE_EXEC;
            next_pcnext = alu_dataout;
         end
         STATE_EXEC: begin
            case (exec_next_stage)
               `EXEC_TO_FETCH:  next_state = STATE_UPDATE_PC;
               `EXEC_TO_LOAD:   next_state = STATE_LOAD1;
               `EXEC_TO_STORE:  next_state = STATE_STORE1;
               `EXEC_TO_BRANCH: next_state = STATE_BRANCH2;
               `EXEC_TO_SYSTEM: next_state = STATE_SYSTEM;
               `EXEC_TO_TRAP:   next_state = STATE_TRAP1;
               default:         next_state = STATE_DEAD;
            endcase
            reg_we = write_reg;
            alu_en = 1;
         end
         STATE_LOAD1: begin
            next_state = STATE_LOAD2;
            bus_en = 1;
            mux_bus_addr_sel = `MUX_BUSADDR_ALU;
            case(dec_funct3)
               `FUNC_LB: begin
                  bus_op = `BUSOP_READB;
               end
               `FUNC_LH: begin
                  bus_op = `BUSOP_READH;
               end
               `FUNC_LW: begin
                  bus_op = `BUSOP_READW;
               end
               `FUNC_LBU: begin
                  bus_op = `BUSOP_READBU;
               end
               `FUNC_LT: begin
                  bus_op = `BUSOP_READT;
               end
               default: begin
                  bus_op = `BUSOP_READHU; // FUNC_LHU
               end
            endcase
         end
         STATE_LOAD2: begin
            next_state = STATE_UPDATE_PC;
            next_writeback_from_bus = 1;
         end
         STATE_STORE1: begin
            next_state = STATE_STORE2;
            bus_en = 1;
            mux_bus_addr_sel = `MUX_BUSADDR_ALU;
            case(dec_funct3)
               `FUNC_SB: begin
                  bus_op = `BUSOP_WRITEB;
               end
               `FUNC_SH: begin
                  bus_op = `BUSOP_WRITEH;
               end
               `FUNC_ST: begin
                  bus_op = `BUSOP_WRITET;
               end
               default: begin
                  bus_op = `BUSOP_WRITEW; // FUNC_SW
               end
            endcase
         end
         STATE_STORE2: begin
            next_state = STATE_UPDATE_PC;
         end
         STATE_BRANCH2: begin
            next_state = STATE_UPDATE_PC;
            // use idle ALU to compute PC+immediate - in case we branch
            alu_en = 1'b1;
            alu_op = `ALUOP_ADD;
            mux_alu_s1_sel = `MUX_ALUDAT1_PC;
            mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            next_branch_pc_from_alu = branch;
         end
         STATE_SYSTEM: begin
            next_state = STATE_UPDATE_PC;
         end
         STATE_TRAP1: begin
            next_state = STATE_UPDATE_PC;
         end
         default: begin
            next_state = STATE_DEAD;
         end
      endcase
   end
/*
            case(dec_opcode)
               `OP_OP: begin
                  alu_en <= 1;
                  mux_alu_s1_sel <= MUX_ALUDAT1_REGVAL1;
                  mux_alu_s2_sel <= MUX_ALUDAT2_REGVAL2;
                  case(dec_funct3)
                     `FUNC_ADD_SUB:  begin
                        case(dec_funct7)
                           7'b0100000:     alu_op <= `ALUOP_SUB;
                           `FUNC7_MUL_DIV: alu_op <= `ALUOP_MUL;
                           default:        alu_op <= `ALUOP_ADD;
                        endcase
                     end
                     `FUNC_SLL:      begin
                        case(dec_funct7)
                           `FUNC7_MUL_DIV: alu_op <= `ALUOP_MULH;
                           default:        alu_op <= `ALUOP_SLL;
                        endcase
                     end
                     `FUNC_SLT:      begin
                        case(dec_funct7)
                           `FUNC7_MUL_DIV: alu_op <= `ALUOP_MULHSU;
                           default:        alu_op <= `ALUOP_SLT;
                        endcase
                     end
                     `FUNC_SLTU:     begin
                        case(dec_funct7)
                           `FUNC7_MUL_DIV: alu_op <= `ALUOP_MULHU;
                           default:        alu_op <= `ALUOP_SLTU;
                        endcase
                     end
                     `FUNC_XOR:      begin
                        case(dec_funct7)
                           `FUNC7_MUL_DIV: alu_op <= `ALUOP_DIV;
                           default:        alu_op <= `ALUOP_XOR;
                        endcase
                     end
                     `FUNC_SRL_SRA:  begin
                        case(dec_funct7)
                           7'b0100000:     alu_op <= `ALUOP_SRA;
                           `FUNC7_MUL_DIV: alu_op <= `ALUOP_DIVU;
                           default:        alu_op <= `ALUOP_SRL;
                        endcase
                     end
                     `FUNC_OR:       begin
                        case(dec_funct7)
                           `FUNC7_MUL_DIV: alu_op <= `ALUOP_REM;
                           default:        alu_op <= `ALUOP_OR;
                        endcase
                     end
                     `FUNC_AND:      begin
                        case(dec_funct7)
                           `FUNC7_MUL_DIV: alu_op <= `ALUOP_REMU;
                           default:        alu_op <= `ALUOP_AND;
                        endcase
                     end
                     default:        alu_op <= `ALUOP_ADD;
                  endcase
                  // do register writeback in FETCH
                  writeback_from_alu <= 1;
                  nextstate <= STATE_PRE_FETCH;
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
                  nextstate <= STATE_PRE_FETCH;
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
      endcase
         end
         default: begin
         end
      endcase
   end


    // only transition to new state if not busy    
    always @(posedge clk) begin
        state <= busy ? state : nextstate; 
    end

    wire addr_misaligned = | (pc[1:0] & 2'b11);
    reg check_tag_on_fetch;
    assign check_tags_o = csr[M_TAGS][0] && check_tag_on_fetch;

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
*/


/*
    always @(posedge clk) begin

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


        csr[M_STATUS] <= csr[M_STATUS];
        csr[M_TAGS] <= csr[M_TAGS];
        csr[M_TVEC] <= csr[M_TVEC];
        csr[M_VENDOR_ID] <= csr[M_VENDOR_ID];

        case(state)
            STATE_RESET: begin
                pcnext <= VECTOR_RESET;
                csr[M_STATUS][3] <= 0; // disable machine-mode external interrupt
                csr[M_TAGS][0] <= 0;
                csr[M_TAGS][2] <= 0;
                nextstate <= STATE_PRE_FETCH;
                csr[M_TVEC] <= VECTOR_EXCEPTION;
                csr[M_VENDOR_ID] <= VENDOR_ID;
                nextpc_from_alu <= 0;
                writeback_from_alu <= 0;
                writeback_from_bus <= 0;
                bus_dataout_stored <= 0;
                check_tag_on_fetch <= 0;
            end
            STATE_PRE_FETCH: begin
                bus_en <= 1;
                bus_op <= `BUSOP_READW;
                mux_bus_addr_sel <= MUX_BUSADDR_PC;
               nextstate <= STATE_FETCH;
                pc <= nextpc_from_alu ? alu_dataout : pcnext;
            end
            STATE_FETCH: begin
                check_tag_on_fetch <= csr[M_TAGS][2];
                // write result of previous instruction to registers if requested
                mux_reg_input_sel <= writeback_from_alu ? MUX_REGINPUT_ALU : MUX_REGINPUT_BUS;
                reg_we <= writeback_from_alu | writeback_from_bus;
                writeback_from_alu <= 0;
                writeback_from_bus <= 0;

                // update PC
//                pc <= nextpc_from_alu ? alu_dataout : pcnext;
                bus_dataout_stored <= bus_dataout;

                // fetch next instruction 
//                bus_en <= 1;
//                bus_op <= `BUSOP_READW;
//                mux_bus_addr_sel <= MUX_BUSADDR_PC;
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
//                bus_dataout_stored <= bus_dataout;

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
                            `FUNC_ADD_SUB:  begin
                                case(dec_funct7)
                                    7'b0100000:     alu_op <= `ALUOP_SUB;
                                    `FUNC7_MUL_DIV: alu_op <= `ALUOP_MUL;
                                    default:        alu_op <= `ALUOP_ADD;
                                endcase
                            end
                            `FUNC_SLL:      begin
                                case(dec_funct7)
                                    `FUNC7_MUL_DIV: alu_op <= `ALUOP_MULH;
                                    default:        alu_op <= `ALUOP_SLL;
                                endcase
                            end
                            `FUNC_SLT:      begin
                                case(dec_funct7)
                                    `FUNC7_MUL_DIV: alu_op <= `ALUOP_MULHSU;
                                    default:        alu_op <= `ALUOP_SLT;
                                endcase
                            end
                            `FUNC_SLTU:     begin
                                case(dec_funct7)
                                    `FUNC7_MUL_DIV: alu_op <= `ALUOP_MULHU;
                                    default:        alu_op <= `ALUOP_SLTU;
                                endcase
                            end
                            `FUNC_XOR:      begin
                                case(dec_funct7)
                                    `FUNC7_MUL_DIV: alu_op <= `ALUOP_DIV;
                                    default:        alu_op <= `ALUOP_XOR;
                                endcase
                            end
                            `FUNC_SRL_SRA:  begin
                                case(dec_funct7)
                                    7'b0100000:     alu_op <= `ALUOP_SRA;
                                    `FUNC7_MUL_DIV: alu_op <= `ALUOP_DIVU;
                                    default:        alu_op <= `ALUOP_SRL;
                                endcase
                            end
                            `FUNC_OR:       begin
                                case(dec_funct7)
                                    `FUNC7_MUL_DIV: alu_op <= `ALUOP_REM;
                                    default:        alu_op <= `ALUOP_OR;
                                endcase
                            end
                            `FUNC_AND:      begin
                                case(dec_funct7)
                                    `FUNC7_MUL_DIV: alu_op <= `ALUOP_REMU;
                                    default:        alu_op <= `ALUOP_AND;
                                endcase
                            end
                            default:        alu_op <= `ALUOP_ADD;
                        endcase
                        // do register writeback in FETCH
                        writeback_from_alu <= 1;
                        nextstate <= STATE_PRE_FETCH;
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
                        nextstate <= STATE_PRE_FETCH;
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
                        nextstate <= STATE_PRE_FETCH;
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
                        nextstate <= STATE_PRE_FETCH;
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
                    `FUNC_LB: begin
                        bus_op <= `BUSOP_READB;
                        check_tag_on_fetch <= csr[M_TAGS][0];
                     end
                    `FUNC_LH: begin
                        bus_op <= `BUSOP_READH;
                        check_tag_on_fetch <= csr[M_TAGS][0];
                     end
                    `FUNC_LW: begin
                        bus_op <= `BUSOP_READW;
                        check_tag_on_fetch <= csr[M_TAGS][0];
                     end
                    `FUNC_LBU: begin
                        bus_op <= `BUSOP_READBU;
                        check_tag_on_fetch <= csr[M_TAGS][0];
                     end
                    `FUNC_LT: begin
                        bus_op <= `BUSOP_READT;
                        check_tag_on_fetch <= 1'b0;
                     end
                    default: begin
                        bus_op <= `BUSOP_READHU; // FUNC_LHU
                        check_tag_on_fetch <= csr[M_TAGS][0];
                     end
                endcase
                //nextstate <= STATE_REGWRITEBUS;
                writeback_from_bus <= 1;
                nextstate <= STATE_FETCH;
            end


            STATE_STORE2: begin // store to computed address
                bus_en <= 1;
                mux_bus_addr_sel <= MUX_BUSADDR_ALU;
                case(dec_funct3)
                    `FUNC_SB: begin
                        bus_op <= `BUSOP_WRITEB;
                        check_tag_on_fetch <= csr[M_TAGS][0];
                     end
                    `FUNC_SH: begin
                        bus_op <= `BUSOP_WRITEH;
                        check_tag_on_fetch <= csr[M_TAGS][0];
                     end
                    `FUNC_ST: begin
                        bus_op <= `BUSOP_WRITET;
                        check_tag_on_fetch <= 1'b0;
                     end
                    default: begin
                        bus_op <= `BUSOP_WRITEW; // FUNC_SW
                        check_tag_on_fetch <= csr[M_TAGS][0];
                     end
                endcase
                // advance to next instruction
                nextstate <= STATE_FETCH;
            end

            STATE_BRANCH2: begin
                // use idle ALU to compute PC+immediate - in case we branch
                alu_en <= 1'b1;
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
                            `SYSTEM_WFI:    nextstate <= STATE_FETCH;
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
            STATE_DEAD: begin
               nextstate <= STATE_DEAD;
            end
            default: begin
               nextstate <= STATE_DEAD;
            end

        endcase


        if(reset) begin
            prevstate <= STATE_RESET;
            nextstate <= STATE_RESET;
        end


    end
*/


endmodule
