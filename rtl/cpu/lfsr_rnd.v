module lfsr_rnd
    #(parameter BITS = 32)
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

    integer i;
    localparam POLY = 32'h80200003;
    always @(posedge clk) begin
        if(I_reset) begin
            result <= 32'hbed4dead;
        end
        else begin
            result[0] <= result[31];
            for (i = 1; i < BITS; i = i + 1) begin
                if (POLY & (1 << i)) result[i] <= result[i - 1] ^ result[31];
                else result[i] <= result[i - 1];
            end
        end
    end

endmodule
