`include "cpu/riscvdefs.vh"
`include "cpu/aludefs.vh"
`include "cpu/cpudefs.vh"

module decoder
(
   input  wire        I_clk,
   input  wire        I_en,
   input  wire [31:0] I_instr,
   output wire [4:0]  O_rs1,
   output wire [4:0]  O_rs2,
   output wire [4:0]  O_rd,
   output wire [31:0] O_imm,
   output reg  [5:0]  O_branchmask,
   output wire [4:0]  alu_oper_o,
   output wire        exec_mux_alu_s1_sel_o,
   output wire [1:0]  exec_mux_alu_s2_sel_o,
   output wire [2:0]  exec_next_stage_o,
   output wire        exec_writeback_from_alu_o,
   output wire        exec_writeback_from_imm_o,
   output wire        exec_next_pc_from_alu_o,
   output wire [1:0]  exec_mux_reg_input_sel_o,
   output wire [2:0]  funct3_o
);
   /*verilator public_module*/ 

   wire [4:0] opcode = I_instr[6:2];
   reg [31:0] imm;

   assign O_imm = imm;

   // combinatorial decode of source register information to allow for register read during decode
   assign O_rs1 = I_instr[19:15];
   assign O_rs2 = I_instr[24:20];
   assign O_rd = I_instr[11:7];

   assign funct3_o = funct3;

   reg isbranch = 0;

   wire [6:0] funct7 = I_instr[31:25];
   wire [2:0] funct3 = I_instr[14:12];

   always @(*) begin
      case(opcode)
         `OP_STORE: imm = {{20{I_instr[31]}}, I_instr[31:25], I_instr[11:8], I_instr[7]}; // S-type
         `OP_BRANCH: imm = {{19{I_instr[31]}}, I_instr[31], I_instr[7], I_instr[30:25], I_instr[11:8], 1'b0}; // SB-type
         `OP_LUI, `OP_AUIPC: imm = {I_instr[31:12], {12{1'b0}}};
         `OP_JAL: imm = {{11{I_instr[31]}}, I_instr[31], I_instr[19:12], I_instr[20], I_instr[30:25], I_instr[24:21], 1'b0}; // UJ-type
         default: imm = {{20{I_instr[31]}}, I_instr[31:20]}; // I-type and R-type. Immediate has no meaning for R-type I_instructions
      endcase

      isbranch = (opcode == `OP_BRANCH);
      O_branchmask = 0;
      case(funct3)
         `FUNC_BEQ:  O_branchmask[0] = isbranch;
         `FUNC_BNE:  O_branchmask[1] = isbranch;
         `FUNC_BLT:  O_branchmask[2] = isbranch;
         `FUNC_BGE:  O_branchmask[3] = isbranch;
         `FUNC_BLTU: O_branchmask[4] = isbranch;
         `FUNC_BGEU: O_branchmask[5] = isbranch;
         default:    O_branchmask    = 6'b0;
      endcase
   end

   reg [4:0] alu_oper;
   reg exec_mux_alu_s1_sel;
   reg [1:0] exec_mux_alu_s2_sel;
   reg [2:0] exec_next_stage;
   reg exec_writeback_from_alu;
   reg exec_writeback_from_imm;
   reg exec_next_pc_from_alu;
   reg [1:0] exec_mux_reg_input_sel;
   assign alu_oper_o = alu_oper;
   assign exec_mux_alu_s1_sel_o = exec_mux_alu_s1_sel;
   assign exec_mux_alu_s2_sel_o = exec_mux_alu_s2_sel;
   assign exec_next_stage_o = exec_next_stage;
   assign exec_writeback_from_alu_o = exec_writeback_from_alu;
   assign exec_writeback_from_imm_o = exec_writeback_from_imm;
   assign exec_next_pc_from_alu_o = exec_next_pc_from_alu;
   assign exec_mux_reg_input_sel_o = exec_mux_reg_input_sel;

   always @ (*) begin
      exec_writeback_from_imm = 0;
      exec_writeback_from_alu = 0;
      case(opcode)
         `OP_OP: begin
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_REGVAL2;
            case(funct3)
               `FUNC_ADD_SUB:  begin
                  case(funct7)
                     7'b0100000:     alu_oper = `ALUOP_SUB;
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_MUL;
                     default:        alu_oper = `ALUOP_ADD;
                  endcase
               end
               `FUNC_SLL:      begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_MULH;
                     default:        alu_oper = `ALUOP_SLL;
                  endcase
               end
               `FUNC_SLT:      begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_MULHSU;
                     default:        alu_oper = `ALUOP_SLT;
                  endcase
               end
               `FUNC_SLTU:     begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_MULHU;
                     default:        alu_oper = `ALUOP_SLTU;
                  endcase
               end
               `FUNC_XOR:      begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_DIV;
                     default:        alu_oper = `ALUOP_XOR;
                  endcase
               end
               `FUNC_SRL_SRA:  begin
                  case(funct7)
                     7'b0100000:     alu_oper = `ALUOP_SRA;
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_DIVU;
                     default:        alu_oper = `ALUOP_SRL;
                  endcase
               end
               `FUNC_OR:       begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_REM;
                     default:        alu_oper = `ALUOP_OR;
                  endcase
               end
               `FUNC_AND:      begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_REMU;
                     default:        alu_oper = `ALUOP_AND;
                  endcase
               end
               default:        alu_oper = `ALUOP_ADD;
            endcase
            // do register writeback in FETCH
            exec_writeback_from_alu = 1;
            exec_next_stage = `EXEC_TO_FETCH;
         end

         `OP_OPIMM: begin
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            case(funct3)
               `FUNC_ADDI:         alu_oper = `ALUOP_ADD;
               `FUNC_SLLI:         alu_oper = `ALUOP_SLL;
               `FUNC_SLTI:         alu_oper = `ALUOP_SLT;
               `FUNC_SLTIU:        alu_oper = `ALUOP_SLTU;
               `FUNC_XORI:         alu_oper = `ALUOP_XOR;
               `FUNC_SRLI_SRAI:    alu_oper = funct7[5] ? `ALUOP_SRA : `ALUOP_SRL;
               `FUNC_ORI:          alu_oper = `ALUOP_OR;
               `FUNC_ANDI:         alu_oper = `ALUOP_AND;
               default:            alu_oper = `ALUOP_ADD;
            endcase
            // do register writeback in FETCH
            exec_writeback_from_alu = 1;
            exec_next_stage = `EXEC_TO_FETCH;
         end

         `OP_LOAD: begin // compute load address on ALU
            alu_oper = `ALUOP_ADD;
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            exec_next_stage = `EXEC_TO_LOAD;
         end

         `OP_STORE:  begin // compute store address on ALU
            alu_oper = `ALUOP_ADD;
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            exec_next_stage = `EXEC_TO_STORE;
         end

         `OP_JAL, `OP_JALR: begin
            // return address computed during decode, write to register
            exec_writeback_from_alu = 1;
            exec_mux_reg_input_sel = `MUX_REGINPUT_ALU;
      
            // compute jal/jalr address
            alu_oper = `ALUOP_ADD;
            exec_mux_alu_s1_sel = (opcode[1]) ? `MUX_ALUDAT1_PC : `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            exec_next_pc_from_alu = 1;
            exec_next_stage = `EXEC_TO_FETCH;
         end
   
         `OP_BRANCH: begin // use ALU for comparisons
            alu_oper = `ALUOP_ADD; // doesn't really matter
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_REGVAL2;
            exec_next_stage = `EXEC_TO_BRANCH;
         end

         `OP_AUIPC: begin // compute PC + IMM on ALU
            alu_oper = `ALUOP_ADD;
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_PC;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            // do register writeback in FETCH
            exec_writeback_from_alu = 1;
            exec_next_stage = `EXEC_TO_FETCH;
         end

         `OP_LUI: begin
            exec_writeback_from_imm = 1;
            exec_mux_reg_input_sel = `MUX_REGINPUT_IMM;
            exec_next_stage = `EXEC_TO_FETCH;
         end

         `OP_MISCMEM:    exec_next_stage = `EXEC_TO_FETCH; // nop
         `OP_SYSTEM:     exec_next_stage = `EXEC_TO_SYSTEM;
         default:        exec_next_stage = `EXEC_TO_TRAP;
      endcase
   end

endmodule
