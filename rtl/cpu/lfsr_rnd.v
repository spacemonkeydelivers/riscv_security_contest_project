module lfsr_rnd
    #(parameter POLY = 32'h80200003)
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

    wire[31:0] to_xor = POLY & {32{result[31]}};
    always @(posedge clk) begin
        if(I_reset) begin
            result <= 32'hbed4dead;
        end
        else begin
            result <= {result[30:0], result[31]} ^ to_xor;
        end
    end

endmodule
