module lfsr_rnd
    #(parameter BITS = 31)
    (
     input        I_clk,
     input        I_reset,
     output[31:0] O_rnd
    );

    wire clk, reset;
    assign clk = I_clk;
    assign reset = I_reset;

	reg[31:0] result;
	assign O_rnd = result;

    reg [31:0] next;
    always @(*) begin
       next = result;
       repeat(BITS) begin
          next = {(next[31]^next[1]), next[31:1]};
       end
    end

    always @(posedge clk) begin
       if(I_reset) begin
          result <= 32'hbed4dead;
       end
       else begin
          result <= next;
       end
    end

endmodule
