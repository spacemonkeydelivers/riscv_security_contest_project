`include "cpu/alu.v"
`include "cpu/wb_cpu_bus.v"
`include "cpu/decoder.v"
`include "cpu/registers.v"
`include "cpu/cpudefs.vh"
`include "cpu/csr.v"

module cpu
#(
   parameter VECTOR_RESET = 32'd0,
   parameter VECTOR_EXCEPTION = 32'd16,
   parameter CPU_USE_NEW_TEST_SEQUENCE = 1'd1,
   parameter CPU_SKIP_TAG_CHECK_ON_SP = 1'd0
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
   output clear_tag_mismatch_o,
   input wire clear_mip_timer_i,
   input wire external_halt_i,
   input wire external_singlestep_i,
   input wire external_do_step_i,
   output wire [31:0] pc_o,
   output wire [4:0]  state_o,
   output wire [31:0] insn_bytes_o,
   output wire        test_finished_o,
   output wire        valid_pc_o
);
   
    assign valid_pc_o = (state == STATE_FETCH) && CYC_O && ACK_I;

    reg test_finished;
    reg next_test_finished;
    assign test_finished_o = test_finished;

    wire interrupt_occured = (TIMER_INTERRUPT_I && irq_timer_en) || TAGS_INTERRUPT_I;
    wire clk, reset;
    assign clk = CLK_I;
    assign reset = RST_I;

    // MSRS
    reg nextpc_from_alu, writeback_from_alu, writeback_from_bus;

    localparam CAUSE_INSTRUCTION_MISALIGNED = 32'h00000000;
    localparam CAUSE_INVALID_INSTRUCTION    = 32'h00000002;
    localparam CAUSE_BREAK                  = 32'h00000003;
    localparam CAUSE_ECALL                  = 32'h0000000b;
    localparam CAUSE_TIMER_INTERRUPT        = 32'h80000007;
    localparam CAUSE_EXTERNAL_INTERRUPT     = 32'h8000000b;
    localparam CAUSE_TAG_MISMATCH           = 32'h80000010;


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
    wire [31:0] reg_flags;

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

    reg [15:0] parcel_low;
    reg [15:0] parcel_high;
    wire [31:0] parcels = {parcel_high, parcel_low};
    assign insn_bytes_o = parcels;
   

    decoder dec_inst(
        .I_clk(clk),
        .I_en(dec_en),
        .I_instr(parcels),
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
        .O_regval2(reg_val2),
        .register_flags_o(reg_flags)
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
            `MUX_ALUDAT2_INSTLEN16: alu_dataS2 = 2;
            default:              alu_dataS2 = 4; // MUX_ALUDAT2_INSTLEN32
        endcase
    end

    reg mux_bus_addr_sel = `MUX_BUSADDR_ALU;
    always @(*) begin
        case(mux_bus_addr_sel)
            `MUX_BUSADDR_ALU: bus_addr = alu_dataout;
            default:         bus_addr = pc; // MUX_BUSADDR_PC
        endcase
    end

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
   wire irq_timer_en;
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
      .csr_irq_timer_en_o (irq_timer_en),
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
    localparam STATE_LOAD1               = 5'd15;
    localparam STATE_MRET_UPDATE_MSTATUS = 5'd16;
    localparam STATE_MRET_READ_EPC       = 5'd17;
    localparam STATE_POST_EXEC           = 5'd18;
    localparam STATE_MISALIGNED_ADDR     = 5'd19;
    localparam STATE_CSR2                = 5'd20;
    localparam STATE_MRET                    = 5'd21;
    localparam STATE_FETCH_MORE              = 5'd22;
    localparam STATE_PREPAIR_UNALIGNED_FETCH = 5'd23;
    localparam STATE_CPU_IDLE                = 5'd24;


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
         mret_state <= MRET_STATE_RESET;
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
            mret_csr_addr = `MSR_MSTATUS;
            mret_csr_data_in = {csr_data_out[31:4], csr_data_out[7], csr_data_out[2:0]};
         end
         MRET_STATE_LOAD_EPC: begin
            next_mret_state = MRET_STATE_IDLE;
            mret_csr_en = 1;
            mret_csr_addr = `MSR_MEPC;
         end
         default: begin
            next_mret_state = MRET_STATE_IDLE;
         end
      endcase
   end
//=================================================================================================


//=================================================================================================
   localparam TRAP_STATE_RESET        = 4'd0;
   localparam TRAP_STATE_IDLE         = 4'd1;
   localparam TRAP_STATE_LOAD_STATUS  = 4'd2;
   localparam TRAP_STATE_STORE_STATUS = 4'd3;
   localparam TRAP_STATE_STORE_EPC    = 4'd4;
   localparam TRAP_STATE_STORE_TVAL   = 4'd5;
   localparam TRAP_STATE_LOAD_TVEC    = 4'd6;
   localparam TRAP_STATE_LOAD_MIP     = 4'd7;
   localparam TRAP_STATE_STORE_MIP    = 4'd8;
   localparam TRAP_STATE_DEAD         = 4'd9;

   reg trap_occured;
   reg [3:0] trap_state;
   reg [3:0] next_trap_state;
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
            trap_csr_addr = `MSR_MSTATUS;
         end
         TRAP_STATE_STORE_STATUS: begin
            next_trap_state = TRAP_STATE_STORE_EPC;
            trap_csr_en = 1;
            trap_csr_we = 1;
            trap_csr_addr = `MSR_MSTATUS;
            trap_csr_data_in = {csr_data_out[31:8], csr_data_out[3], csr_data_out[6:4], 1'b0, csr_data_out[2:0]};
         end
         TRAP_STATE_STORE_EPC: begin
            next_trap_state = TRAP_STATE_STORE_TVAL;
            trap_csr_en = 1;
            trap_csr_we = 1;
            trap_csr_addr = `MSR_MEPC;
            trap_csr_data_in = pc;
         end
         TRAP_STATE_STORE_TVAL: begin
            next_trap_state = (TIMER_INTERRUPT_I && irq_timer_en) ? TRAP_STATE_LOAD_MIP : TRAP_STATE_LOAD_TVEC;
            trap_csr_en = 1;
            trap_csr_we = 1;
            trap_csr_addr = `MSR_MTVAL;
            trap_csr_data_in = pc;
         end
         TRAP_STATE_LOAD_MIP: begin
            next_trap_state = TRAP_STATE_STORE_MIP;
            trap_csr_en = 1;
            trap_csr_addr = `MSR_MIP;
         end
         TRAP_STATE_STORE_MIP: begin
            next_trap_state = TRAP_STATE_LOAD_TVEC;
            trap_csr_en = 1;
            trap_csr_we = 1;
            trap_csr_addr = `MSR_MIP;
            trap_csr_data_in = {csr_data_out[31:8], 1'b1, csr_data_out[6:0]};
         end
         TRAP_STATE_LOAD_TVEC: begin
            next_trap_state = TRAP_STATE_IDLE;
            trap_csr_en = 1;
            trap_csr_addr = `MSR_MTVEC;
         end
         default: begin
            next_trap_state = TRAP_STATE_DEAD;
         end
      endcase
   end
//=================================================================================================
    wire busy;
    assign busy = alu_busy | bus_busy | csr_busy | handling_trap | handling_mret | external_halt_i;

    // evaluate branch conditions
    wire branch;
    assign branch = (dec_branchmask & {!alu_ltu, alu_ltu, !alu_lt, alu_lt, !alu_eq, alu_eq}) != 0;


   reg [4:0] state /* verilator public */;
   reg [4:0] next_state;
   assign state_o = state;
   assign pc_o = pc;

   reg [31:0] pc /* verilator public */;
   /* verilator lint_off UNOPT */
   reg [31:0] next_pc;
   /* verilator lint_on UNOPT */

   reg update_pc;

   reg [31:0] pcnext;
   reg [31:0] next_pcnext;

   reg next_writeback_from_bus;

   reg branch_pc_from_alu;
   reg next_branch_pc_from_alu;
   reg next_addr_from_csr;

   reg check_tags;
   reg next_check_tags;

   reg [31:0] prev_pc;

   reg [31:0] insn_counter;

   always @ (posedge clk) begin
      if (reset) begin
         state <= STATE_RESET;
         pc <= (VECTOR_RESET);
         pcnext <= 0;
         writeback_from_bus <= 0;
         branch_pc_from_alu <= 0;
         next_addr_from_csr <= 0;
         check_tags <= 0;
         prev_pc <= 0;
         exec_done <= 0;
         test_finished <= 0;
         insn_counter <= 0;
      end
      else begin

         case (state) 
             STATE_FETCH: begin
                if (pc[1] == 1) begin
                    parcel_low <= bus_dataout[31:16];
                    parcel_high <= 0;
                end
                else begin
                    parcel_low <= bus_dataout[15:0];
                    parcel_high <= bus_dataout[31:16];
                end
             end
             STATE_FETCH_MORE: begin
                 parcel_high <= bus_dataout[15:0];
             end
             default: begin
                parcel_low <= parcel_low;
                parcel_high <= parcel_high;
             end
         endcase

         state <= busy ? state : next_state;
         pc <= (update_pc && !busy) ? next_pc : pc;
         prev_pc <= (update_pc && !busy) ? pc : prev_pc;
         pcnext <= ((state == STATE_DECODE) && !busy) ? next_pcnext : pcnext;
         writeback_from_bus <= (busy) ? writeback_from_bus : next_writeback_from_bus;
         branch_pc_from_alu <= next_branch_pc_from_alu;
         next_addr_from_csr <= (busy) ? next_addr_from_csr : next_pc_from_csr;
         check_tags <= (    (state == STATE_PRE_FETCH)
                         || (state == STATE_LOAD1)
                         || (state == STATE_STORE1))
                     ? next_check_tags : check_tags;
         exec_done <= ((state == STATE_PRE_FETCH) || (state == STATE_EXEC)) ? next_exec_done : exec_done;
         test_finished <= test_finished ? test_finished : next_test_finished;
`ifdef SIMULATION_RUN
         insn_counter <= (state == STATE_DECODE) ? insn_counter + 1 : insn_counter;
`endif
      end
   end

   reg next_pc_from_csr;
   // TODO: we should add an assert here, this should not really happen
   wire addr_misaligned = |next_pc[0];

   reg exec_done;
   reg next_exec_done;

   reg check;
   always @ (*) begin
      next_exec_done = 0;
      next_check_tags = 0;
      trap_occured = 0;
      mret_occured = 0;

      next_pc_from_csr = 0;
      update_pc = 0;
      
      bus_en = 0;
      dec_en = 0;
      alu_en = 0;

      next_pcnext = 0;
      alu_op = 0;
      reg_we = 0;
      reg_re = 0;

      bus_op = `BUSOP_READW;
      mux_bus_addr_sel = `MUX_BUSADDR_ALU;
            
      writeback_from_alu = 0;
      next_writeback_from_bus = 0;
      next_pc = 0;

      mux_reg_input_sel = 0;
      next_branch_pc_from_alu = 0;
      mux_alu_s2_sel = 0;
      mux_alu_s1_sel = 0;

      csr_en = 0;
      csr_we = 0;
      csr_addr = 0;
      csr_data_in = 0;

      next_test_finished = 0;

      case (state)
         STATE_RESET: begin
            next_state = STATE_PRE_FETCH;
         end
         STATE_UPDATE_PC: begin
            update_pc = 1;
            next_state = external_singlestep_i || test_finished ? STATE_CPU_IDLE : 
                         addr_misaligned                        ? STATE_TRAP     :
                                                                  STATE_PRE_FETCH;
            next_pc = (next_pc_from_csr || next_addr_from_csr)      ? csr_data_out & ~32'h1 :
                      (exec_next_pc_from_alu || branch_pc_from_alu) ? alu_dataout & ~32'h1 :
                                                                      pcnext & ~32'h1;
            mux_reg_input_sel = (writeback_from_alu || exec_writeback_from_alu) ? `MUX_REGINPUT_ALU :
                                (exec_writeback_from_imm                      ) ?  exec_mux_reg_input_sel :
                                                                                  `MUX_REGINPUT_BUS;
            reg_we = (writeback_from_alu || writeback_from_bus || exec_writeback_from_imm || exec_writeback_from_alu) && exec_done;
            if (addr_misaligned) begin
               trap_occured = 1;
               csr_en = 1;
               csr_we = 1;
               csr_addr = `MSR_MCAUSE;
               csr_data_in = CAUSE_INSTRUCTION_MISALIGNED;
            end
         end
         STATE_PREPAIR_UNALIGNED_FETCH: begin
            next_state = STATE_FETCH_MORE;
            mux_bus_addr_sel = `MUX_BUSADDR_ALU;
            bus_en = 1;
            bus_op = `BUSOP_READW;
            next_check_tags = tags_if_en;
         end
         STATE_PRE_FETCH: begin
            next_exec_done = 0;
            next_state = STATE_FETCH;
            mux_bus_addr_sel = `MUX_BUSADDR_PC;
            bus_en = 1;
            bus_op = `BUSOP_READW;
            next_check_tags = tags_if_en;
         end
         STATE_FETCH_MORE: begin
             alu_en = 1;
             mux_alu_s1_sel = `MUX_ALUDAT1_PC;
             mux_alu_s2_sel = `MUX_ALUDAT2_INSTLEN32 ;
             next_state = STATE_DECODE;
         end
         STATE_FETCH: begin
             if (pc[1] == 1) begin
                 alu_en = 1;
                 mux_alu_s1_sel = `MUX_ALUDAT1_PC;
                 mux_alu_s2_sel = `MUX_ALUDAT2_INSTLEN16;

                 if (bus_dataout[17:16] == 3) begin
                    next_state = STATE_PREPAIR_UNALIGNED_FETCH ;
                 end
                 else begin
                    next_state = STATE_DECODE;
                 end
             end
             else begin
                alu_en = 1;
                mux_alu_s1_sel = `MUX_ALUDAT1_PC;
                mux_alu_s2_sel = (bus_dataout[1:0] == 3)
                              ? `MUX_ALUDAT2_INSTLEN32 : `MUX_ALUDAT2_INSTLEN16;
                next_state = STATE_DECODE;
             end
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
                csr_addr = `MSR_MCAUSE;
                csr_we = 1;
                if (TAGS_INTERRUPT_I && tags_en) begin
                    csr_data_in = CAUSE_TAG_MISMATCH;
                end else if (TIMER_INTERRUPT_I) begin
                    csr_data_in = CAUSE_TIMER_INTERRUPT;
                end
            end
         end
         STATE_EXEC: begin
            next_exec_done = 1;
            case (exec_next_stage)
               `EXEC_TO_FETCH:  next_state = STATE_POST_EXEC;
//               `EXEC_TO_FETCH:  next_state = STATE_UPDATE_PC;
               `EXEC_TO_LOAD:   next_state = STATE_LOAD1;
               `EXEC_TO_STORE:  next_state = STATE_STORE1;
               `EXEC_TO_BRANCH: next_state = STATE_BRANCH2;
               `EXEC_TO_SYSTEM: next_state = STATE_SYSTEM;
               `EXEC_TO_TRAP:   next_state = STATE_TRAP;
               default:         next_state = STATE_DEAD;
            endcase
            alu_en = 1;
            if (exec_next_pc_from_alu) begin
               reg_we = write_reg;
            end
         end
         STATE_POST_EXEC: begin
            next_state = STATE_UPDATE_PC;
//            alu_en = 1;
            if (!exec_next_pc_from_alu) begin
               reg_we = write_reg;
            end
         end
         STATE_LOAD1: begin
            next_state = STATE_LOAD2;
            bus_en = 1;
            mux_bus_addr_sel = `MUX_BUSADDR_ALU;
            case(dec_funct3)
               `FUNC_LB: begin
                  bus_op = `BUSOP_READB;
                  next_check_tags = (CPU_SKIP_TAG_CHECK_ON_SP ? ((dec_rs1== 5'd2) ? 1'd0 : tags_en) : tags_en);
               end
               `FUNC_LH: begin
                  bus_op = `BUSOP_READH;
                  next_check_tags = (CPU_SKIP_TAG_CHECK_ON_SP ? ((dec_rs1== 5'd2) ? 1'd0 : tags_en) : tags_en);
               end
               `FUNC_LW: begin
                  bus_op = `BUSOP_READW;
                  next_check_tags = (CPU_SKIP_TAG_CHECK_ON_SP ? ((dec_rs1== 5'd2) ? 1'd0 : tags_en) : tags_en);
               end
               `FUNC_LBU: begin
                  bus_op = `BUSOP_READBU;
                  next_check_tags = (CPU_SKIP_TAG_CHECK_ON_SP ? ((dec_rs1== 5'd2) ? 1'd0 : tags_en) : tags_en);
               end
               `FUNC_LT: begin
                  bus_op = `BUSOP_READT;
               end
               default: begin
                  next_check_tags = (CPU_SKIP_TAG_CHECK_ON_SP ? ((dec_rs1== 5'd2) ? 1'd0 : tags_en) : tags_en);
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
                  next_check_tags = (CPU_SKIP_TAG_CHECK_ON_SP ? ((dec_rs1== 5'd2) ? 1'd0 : tags_en) : tags_en);
                  bus_op = `BUSOP_WRITEB;
               end
               `FUNC_SH: begin
                  next_check_tags = (CPU_SKIP_TAG_CHECK_ON_SP ? ((dec_rs1== 5'd2) ? 1'd0 : tags_en) : tags_en);
                  bus_op = `BUSOP_WRITEH;
               end
               `FUNC_ST: begin
                  bus_op = `BUSOP_WRITET;
               end
               default: begin
                  next_check_tags = (CPU_SKIP_TAG_CHECK_ON_SP ? ((dec_rs1== 5'd2) ? 1'd0 : tags_en) : tags_en);
                  bus_op = `BUSOP_WRITEW; // FUNC_SW
               end
            endcase
            csr_en = 1;
            csr_addr = `MSR_MIP;
         end
         STATE_STORE2: begin
            next_state = STATE_UPDATE_PC;
            if (clear_mip_timer_i) begin
               csr_en = 1;
               csr_we = 1;
               csr_addr = `MSR_MIP;
               csr_data_in = {csr_data_out[31:8], 1'b0, csr_data_out[6:0]};
            end
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
                        csr_addr = `MSR_MCAUSE;
                        csr_we = 1;
                        csr_data_in = CAUSE_ECALL;
                        if (CPU_USE_NEW_TEST_SEQUENCE && reg_flags[2]) begin
                           next_test_finished = 1;
                        end
                     end
                     `SYSTEM_EBREAK: begin
                        trap_occured = 1;
                        next_state = STATE_TRAP;
                        csr_en = 1;
                        csr_addr = `MSR_MCAUSE;
                        csr_we = 1;
                        csr_data_in = CAUSE_BREAK;
                     end
                     `SYSTEM_WFI: begin
                        next_state = STATE_UPDATE_PC;
                     end
                     `SYSTEM_MRET: begin
                        csr_en = 1;
                        csr_addr = `MSR_MSTATUS;
                        next_state = STATE_MRET;
                        mret_occured = 1;
                     end
                     default: begin
                        trap_occured = 1;
                        next_state = STATE_TRAP;
                        csr_en = 1;
                        csr_addr = `MSR_MCAUSE;
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
                  csr_addr = `MSR_MCAUSE;
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
            csr_addr = `MSR_MSTATUS;
            csr_data_in = {csr_data_out[31:4], csr_data_out[7], csr_data_out[2:0]};
         end
         STATE_MRET_READ_EPC: begin
            next_state = STATE_UPDATE_PC;
            csr_en = 1;
            csr_addr = `MSR_MEPC;
            csr_op_type = 0;
            next_pc_from_csr = 1;
         end
         STATE_CPU_IDLE: begin
            next_state = external_do_step_i ? STATE_PRE_FETCH :
                         test_finished      ? STATE_CPU_IDLE  :
                                              STATE_CPU_IDLE;
         end
         default: begin
            next_state = STATE_DEAD;
         end
      endcase
   end
endmodule
