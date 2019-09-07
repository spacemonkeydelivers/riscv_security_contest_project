`include "cpu/alu.v"
`include "cpu/wb_cpu_bus.v"
`include "cpu/decoder.v"
`include "cpu/registers.v"
`include "cpu/lfsr_rnd.v"
`include "cpu/cpudefs.vh"
`include "cpu/csr.v"

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
    assign alu_op_final = ((state == STATE_EXEC) || (state == STATE_POST_EXEC)) ? dec_alu_oper : alu_op;

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
    assign clear_tag_mismatch_o = tags_irq_clear;
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
    assign mux_alu_s1_sel_f = ((state == STATE_EXEC) || (state == STATE_POST_EXEC)) ? exec_mux_alu_s1_sel : mux_alu_s1_sel;
    always @(*) begin
        case(mux_alu_s1_sel_f)
            `MUX_ALUDAT1_REGVAL1: alu_dataS1 = reg_val1;
            default:             alu_dataS1 = pc; // MUX_ALUDAT1_PC
        endcase
    end

    wire [1:0] mux_alu_s2_sel_f;
    reg[1:0] mux_alu_s2_sel = `MUX_ALUDAT2_REGVAL2;
    assign mux_alu_s2_sel_f = ((state == STATE_EXEC) || (state == STATE_POST_EXEC)) ? exec_mux_alu_s2_sel : mux_alu_s2_sel;
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
                     M_LAST      = 17;
    
   reg csr_en;
   reg csr_we;
   reg [11:0] csr_addr;
   reg [31:0] csr_data_in;
   wire [31:0] csr_data_out;
   wire csr_busy;
   wire csr_exists;
   wire csr_ro;
   
   reg mret_csr_en;
   reg mret_csr_we;
   reg [11:0] mret_csr_addr;
   reg [31:0] mret_csr_data_in;

   reg trap_csr_en;
   reg trap_csr_we;
   reg [11:0] trap_csr_addr;
   reg [31:0] trap_csr_data_in;

   wire csr_en_f = (handling_trap) ? trap_csr_en :
                   (handling_mret) ? mret_csr_en : 
                                     csr_en;
   wire csr_we_f = (handling_trap) ? trap_csr_we :
                   (handling_mret) ? mret_csr_we : 
                                     csr_we;
   wire [11:0] csr_addr_f = (handling_trap) ? trap_csr_addr :
                            (handling_mret) ? mret_csr_addr :
                                              csr_addr;
   wire [31:0] csr_data_in_f = (handling_trap) ? trap_csr_data_in :
                               (handling_mret) ? mret_csr_data_in : 
                                                 csr_data_in;

   wire irq_en;
   wire tags_en;
   wire tags_if_en;
   wire tags_irq_clear;
   assign check_tags_o = check_tags;

   csr
   csr0
   (
      .clk_i (clk),
      .rst_i (reset),
      .csr_en_i (csr_en_f),
      .csr_we_i (csr_we_f),
      .csr_addr_i (csr_addr_f),
      .csr_data_i (csr_data_in_f),
      .csr_data_o (csr_data_out),
      .csr_busy_o (csr_busy),
      .csr_exists_o (csr_exists),
      .csr_ro_o (csr_ro),
      .csr_irq_en_o (irq_en),
      .csr_tags_en_o (tags_en),
      .csr_tags_if_en_o (tags_if_en),
      .csr_tags_irq_clear_o (tags_irq_clear)
   );

    reg [1:0] mux_reg_input_sel = `MUX_REGINPUT_ALU;
    always @(*) begin
        case(mux_reg_input_sel)
            `MUX_REGINPUT_ALU:     reg_datain = alu_dataout;
            `MUX_REGINPUT_BUS:     reg_datain = bus_dataout;
            `MUX_REGINPUT_IMM:     reg_datain = dec_imm;
            `MUX_REGINPUT_MSR:     reg_datain = csr_data_out;
            default:               reg_datain = 32'hFFFFFFFF;
        endcase
    end

    localparam STATE_RESET          = 5'd0;
    localparam STATE_FETCH          = 5'd1;
    localparam STATE_DECODE         = 5'd2;
    localparam STATE_EXEC           = 5'd3;
    localparam STATE_STORE2         = 5'd5;
    localparam STATE_LOAD2          = 5'd6;
    localparam STATE_BRANCH2        = 5'd7;
    localparam STATE_TRAP           = 5'd8;
    localparam STATE_SYSTEM         = 5'd9;
    localparam STATE_UPDATE_PC      = 5'd10;
    localparam STATE_CSR1           = 5'd11;
    localparam STATE_DEAD           = 5'd12;
    localparam STATE_PRE_FETCH      = 5'd13;
    localparam STATE_STORE1         = 5'd14;
    localparam STATE_LOAD1          = 5'd15;
    localparam STATE_MRET_UPDATE_MSTATUS = 5'd16;
    localparam STATE_MRET_READ_EPC       = 5'd17;
    localparam STATE_POST_EXEC       = 5'd18;
    localparam STATE_MISALIGNED_ADDR = 5'd19;
    localparam STATE_CSR2    = 5'd20;
    localparam STATE_MRET    = 5'd21;


   reg [1:0] csr_op_type;

//=================================================================================================
   localparam MRET_STATE_RESET        = 2'd0;
   localparam MRET_STATE_IDLE         = 2'd1;
   localparam MRET_STATE_STORE_STATUS = 2'd2;
   localparam MRET_STATE_LOAD_EPC     = 2'd3;

   reg mret_occured;
   reg [1:0] mret_state;
   reg [1:0] next_mret_state;
   reg mret_busy;
   wire handling_mret = !((mret_state == MRET_STATE_RESET) || (mret_state == MRET_STATE_IDLE));
   
   always @ (posedge clk) begin
      if (reset) begin
         mret_state <= TRAP_STATE_RESET;
      end else begin
         mret_state <= (csr_busy) ? mret_state : next_mret_state;
      end
   end

   always @ (*) begin
      mret_csr_en = 0;
      mret_csr_we = 0;
      mret_csr_addr = 0;
      mret_csr_data_in = 0;

      case (mret_state)
         MRET_STATE_RESET: begin
            next_mret_state = MRET_STATE_IDLE;
         end
         MRET_STATE_IDLE: begin
            next_mret_state = (mret_occured) ? MRET_STATE_STORE_STATUS : MRET_STATE_IDLE;
         end
         MRET_STATE_STORE_STATUS: begin
            next_mret_state = MRET_STATE_LOAD_EPC;
            mret_csr_en = 1;
            mret_csr_we = 1;
            mret_csr_addr = MSR_MSTATUS;
            mret_csr_data_in = {csr_data_out[31:4], csr_data_out[7], csr_data_out[2:0]};
         end
         MRET_STATE_LOAD_EPC: begin
            next_mret_state = MRET_STATE_IDLE;
            mret_csr_en = 1;
            mret_csr_addr = MSR_MEPC;
         end
         default: begin
            next_mret_state = MRET_STATE_IDLE;
         end
      endcase
   end
//=================================================================================================


//=================================================================================================
   localparam TRAP_STATE_RESET        = 3'd0;
   localparam TRAP_STATE_IDLE         = 3'd1;
   localparam TRAP_STATE_LOAD_STATUS  = 3'd2;
   localparam TRAP_STATE_STORE_STATUS = 3'd3;
   localparam TRAP_STATE_STORE_EPC    = 3'd4;
   localparam TRAP_STATE_STORE_TVAL   = 3'd5;
   localparam TRAP_STATE_LOAD_TVEC    = 3'd6;
   localparam TRAP_STATE_DEAD         = 3'd7;

   reg trap_occured;
   reg [2:0] trap_state;
   reg [2:0] next_trap_state;
   wire handling_trap = !((trap_state == TRAP_STATE_RESET) || (trap_state == TRAP_STATE_IDLE));

   always @ (posedge clk) begin
      if (reset) begin
         trap_state <= TRAP_STATE_RESET;
      end else begin
         trap_state <= (csr_busy) ? trap_state : next_trap_state;
      end
   end

   always @ (*) begin
      trap_csr_en = 0;
      trap_csr_we = 0;
      trap_csr_addr = 0;
      trap_csr_data_in = 0;

      case (trap_state)
         TRAP_STATE_RESET: begin
            next_trap_state = TRAP_STATE_IDLE;
         end
         TRAP_STATE_IDLE: begin
            next_trap_state = (trap_occured) ? TRAP_STATE_LOAD_STATUS : TRAP_STATE_IDLE;
         end
         TRAP_STATE_LOAD_STATUS: begin
            next_trap_state = TRAP_STATE_STORE_STATUS;
            trap_csr_en = 1;
            trap_csr_addr = MSR_MSTATUS;
         end
         TRAP_STATE_STORE_STATUS: begin
            next_trap_state = TRAP_STATE_STORE_EPC;
            trap_csr_en = 1;
            trap_csr_we = 1;
            trap_csr_addr = MSR_MSTATUS;
            trap_csr_data_in = {csr_data_out[31:8], csr_data_out[3], csr_data_out[6:4], 1'b0, csr_data_out[2:0]};
         end
         TRAP_STATE_STORE_EPC: begin
            next_trap_state = TRAP_STATE_STORE_TVAL;
            trap_csr_en = 1;
            trap_csr_we = 1;
            trap_csr_addr = MSR_MEPC;
            trap_csr_data_in = pc;
         end
         TRAP_STATE_STORE_TVAL: begin
            next_trap_state = TRAP_STATE_LOAD_TVEC;
            trap_csr_en = 1;
            trap_csr_we = 1;
            trap_csr_addr = MSR_MTVAL;
            trap_csr_data_in = pc;
         end
         TRAP_STATE_LOAD_TVEC: begin
            next_trap_state = TRAP_STATE_IDLE;
            trap_csr_en = 1;
            trap_csr_addr = MSR_MTVEC;
         end
         default: begin
            next_trap_state = TRAP_STATE_DEAD;
         end
      endcase
   end
//=================================================================================================
    wire busy;
    assign busy = alu_busy | bus_busy | csr_busy | handling_trap | handling_mret;

    // evaluate branch conditions
    wire branch;
    assign branch = (dec_branchmask & {!alu_ltu, alu_ltu, !alu_lt, alu_lt, !alu_eq, alu_eq}) != 0;


   reg [4:0] state;
   reg [4:0] next_state;

   reg [31:0] pc;
   reg [31:0] next_pc;

   reg update_pc;

   reg [31:0] pcnext;
   reg [31:0] next_pcnext;

   reg next_writeback_from_bus;

   reg branch_pc_from_alu;
   reg next_branch_pc_from_alu;
   reg next_addr_from_csr;

   reg check_tags;
   reg next_check_tags;

   always @ (posedge clk) begin
      if (reset) begin
         state <= STATE_RESET;
         pc <= (VECTOR_RESET);
         pcnext <= 0;
         writeback_from_bus <= 0;
         bus_dataout_stored <= 0;
         branch_pc_from_alu <= 0;
         next_addr_from_csr <= 0;
         check_tags <= 0;
      end
      else begin
         state <= busy ? state : next_state;
//         pc <= (update_pc && !busy) ? next_pc : pc;
         pc <= (update_pc && !busy) ? next_pc : pc;
         pcnext <= ((state == STATE_DECODE) && !busy) ? next_pcnext : pcnext;
         writeback_from_bus <= (busy) ? writeback_from_bus : next_writeback_from_bus;
         bus_dataout_stored <= (state == STATE_FETCH) ? bus_dataout : bus_dataout_stored;
         branch_pc_from_alu <= next_branch_pc_from_alu;
         next_addr_from_csr <= (busy) ? next_addr_from_csr : next_pc_from_csr;
         check_tags <= ((state == STATE_PRE_FETCH) || (state == STATE_LOAD1) || (state == STATE_STORE1)) ? next_check_tags : check_tags;
      end
   end

   reg next_pc_from_csr;
   wire addr_misaligned = |next_pc[1:0];

   reg check;
   always @ (*) begin
      next_check_tags = 0;
      trap_occured = 0;
      mret_occured = 0;

      next_pc_from_csr = 0;
      update_pc = 0;
      
      bus_en = 0;
      dec_en = 0;
      alu_en = 0;

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

      csr_en = 0;
      csr_we = 0;
      csr_addr = 0;
      csr_data_in = 0;

      case (state)
         STATE_RESET: begin
            next_state = STATE_PRE_FETCH;
         end
         STATE_UPDATE_PC: begin
            update_pc = 1;
            next_state = addr_misaligned ? STATE_TRAP : STATE_PRE_FETCH;
            next_pc = (next_pc_from_csr || next_addr_from_csr)      ? csr_data_out & ~32'h1 :
                      (exec_next_pc_from_alu || branch_pc_from_alu) ? alu_dataout & ~32'h1 :
                                                                      pcnext & ~32'h1;
            mux_reg_input_sel = (writeback_from_alu || exec_writeback_from_alu) ? `MUX_REGINPUT_ALU :
                                (exec_writeback_from_imm                      ) ?  exec_mux_reg_input_sel :
                                                                                  `MUX_REGINPUT_BUS;
            reg_we = writeback_from_alu || writeback_from_bus || exec_writeback_from_imm || exec_writeback_from_alu;
            if (addr_misaligned) begin
               trap_occured = 1;
               csr_en = 1;
               csr_we = 1;
               csr_addr = MSR_MCAUSE;
               csr_data_in = CAUSE_INSTRUCTION_MISALIGNED;
            end
         end
         STATE_PRE_FETCH: begin
            next_state = STATE_FETCH;
            mux_bus_addr_sel = `MUX_BUSADDR_PC;
            next_state = STATE_FETCH;
            bus_en = 1;
            bus_op = `BUSOP_READW;
            next_check_tags = tags_if_en;
         end
         STATE_FETCH: begin
            // ALU is unused... let's compute PC+4!
            alu_en = 1;
            mux_alu_s1_sel = `MUX_ALUDAT1_PC;
            mux_alu_s2_sel = `MUX_ALUDAT2_INSTLEN;
            next_state = STATE_DECODE;
         end
         STATE_DECODE: begin
            dec_en = 1;
            reg_re = 1;
            next_state = STATE_EXEC;
            next_pcnext = alu_dataout;
            if (interrupt_occured && irq_en) begin
               trap_occured = 1;
               next_state = STATE_TRAP;
               csr_en = 1;
               csr_addr = MSR_MCAUSE;
               csr_we = 1;
               if (TAGS_INTERRUPT_I && tags_en) begin
                  csr_data_in = CAUSE_TAG_MISMATCH;
               end
               if (TIMER_INTERRUPT_I) begin
                  csr_data_in = CAUSE_EXTERNAL_INTERRUPT;
               end
            end
         end
         STATE_EXEC: begin
            case (exec_next_stage)
//               `EXEC_TO_FETCH:  next_state = STATE_POST_EXEC;
               `EXEC_TO_FETCH:  next_state = STATE_UPDATE_PC;
               `EXEC_TO_LOAD:   next_state = STATE_LOAD1;
               `EXEC_TO_STORE:  next_state = STATE_STORE1;
               `EXEC_TO_BRANCH: next_state = STATE_BRANCH2;
               `EXEC_TO_SYSTEM: next_state = STATE_SYSTEM;
               `EXEC_TO_TRAP:   next_state = STATE_TRAP;
               default:         next_state = STATE_DEAD;
            endcase
            alu_en = 1;
            reg_we = write_reg;
         end
         STATE_POST_EXEC: begin
            next_state = STATE_UPDATE_PC;
//            alu_en = 1;
//            reg_we = write_reg;
         end
         STATE_LOAD1: begin
            next_state = STATE_LOAD2;
            bus_en = 1;
            mux_bus_addr_sel = `MUX_BUSADDR_ALU;
            case(dec_funct3)
               `FUNC_LB: begin
                  bus_op = `BUSOP_READB;
                  next_check_tags = tags_en;
               end
               `FUNC_LH: begin
                  bus_op = `BUSOP_READH;
                  next_check_tags = tags_en;
               end
               `FUNC_LW: begin
                  bus_op = `BUSOP_READW;
                  next_check_tags = tags_en;
               end
               `FUNC_LBU: begin
                  bus_op = `BUSOP_READBU;
                  next_check_tags = tags_en;
               end
               `FUNC_LT: begin
                  bus_op = `BUSOP_READT;
               end
               default: begin
                  next_check_tags = tags_en;
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
                  next_check_tags = tags_en;
                  bus_op = `BUSOP_WRITEB;
               end
               `FUNC_SH: begin
                  next_check_tags = tags_en;
                  bus_op = `BUSOP_WRITEH;
               end
               `FUNC_ST: begin
                  bus_op = `BUSOP_WRITET;
               end
               default: begin
                  next_check_tags = tags_en;
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
            next_state = STATE_TRAP;
            case(dec_funct3)
               `FUNC_ECALL_EBREAK: begin
                  // handle ecall, ebreak and mret here
                  case(dec_imm[11:0])
                     `SYSTEM_ECALL: begin
                        trap_occured = 1;
                        next_state = STATE_TRAP;
                        csr_en = 1;
                        csr_addr = MSR_MCAUSE;
                        csr_we = 1;
                        csr_data_in = CAUSE_ECALL;
                     end
                     `SYSTEM_EBREAK: begin
                        trap_occured = 1;
                        next_state = STATE_TRAP;
                        csr_en = 1;
                        csr_addr = MSR_MCAUSE;
                        csr_we = 1;
                        csr_data_in = CAUSE_BREAK;
                     end
                     `SYSTEM_WFI: begin
                        next_state = STATE_UPDATE_PC;
                     end
                     `SYSTEM_MRET: begin
                        csr_en = 1;
                        csr_addr = MSR_MSTATUS;
                        next_state = STATE_MRET;
                        mret_occured = 1;
                     end
                     default: begin
                        trap_occured = 1;
                        next_state = STATE_TRAP;
                        csr_en = 1;
                        csr_addr = MSR_MCAUSE;
                        csr_we = 1;
                        csr_data_in = CAUSE_INVALID_INSTRUCTION;
                     end
                  endcase
               end

               `FUNC_CSRRW, `FUNC_CSRRWI, `FUNC_CSRRSI, `FUNC_CSRRS, `FUNC_CSRRCI, `FUNC_CSRRC: begin
                  next_state = STATE_CSR1;
                  csr_en = 1;
                  csr_addr = dec_imm[11:0];
               end

               // unsupported SYSTEM instruction
               default: begin
                  trap_occured = 1;
                  next_state = STATE_TRAP;
                  csr_en = 1;
                  csr_addr = MSR_MCAUSE;
                  csr_we = 1;
                  csr_data_in = CAUSE_INVALID_INSTRUCTION;
               end
            endcase
         end
         STATE_CSR1: begin
            mux_reg_input_sel = `MUX_REGINPUT_MSR;
            reg_we = 1;
            next_state = STATE_CSR2;
         end
         STATE_CSR2: begin
            next_state = STATE_UPDATE_PC;
            csr_en = 1;
            csr_addr = dec_imm[11:0];
            csr_we = 1;
            case (dec_funct3)
               `FUNC_CSRRW: begin
                  csr_data_in = reg_val1;
               end
               `FUNC_CSRRWI: begin
                  csr_data_in = {27'b0, dec_rs1};
               end
               `FUNC_CSRRSI: begin
                  csr_data_in = ({27'b0, dec_rs1}) | csr_data_out;
               end
               `FUNC_CSRRS: begin
                  csr_data_in = reg_val1 | csr_data_out;
               end
               `FUNC_CSRRCI: begin
                  csr_data_in = ~({27'b0, dec_rs1}) & (csr_data_out);
               end
               `FUNC_CSRRC: begin
                  csr_data_in = ~reg_val1 & (csr_data_out);
               end
               default: begin
                  csr_data_in = 32'hB0010BAD;
               end
            endcase
         end

         STATE_TRAP: begin
            next_state = STATE_UPDATE_PC;
            next_pc_from_csr = 1;
         end

         STATE_MRET: begin
            next_state = STATE_UPDATE_PC;
            next_pc_from_csr = 1;
         end

         STATE_MRET_UPDATE_MSTATUS: begin
            next_state = STATE_MRET_READ_EPC;
            csr_en = 1;
            csr_op_type = 1;
            csr_addr = MSR_MSTATUS;
            csr_data_in = {csr_data_out[31:4], csr_data_out[7], csr_data_out[2:0]};
         end
         STATE_MRET_READ_EPC: begin
            next_state = STATE_UPDATE_PC;
            csr_en = 1;
            csr_addr = MSR_MEPC;
            csr_op_type = 0;
            next_pc_from_csr = 1;
         end
         default: begin
            next_state = STATE_DEAD;
         end
      endcase
   end


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
                    default:        nextstate <= STATE_TRAP;
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
