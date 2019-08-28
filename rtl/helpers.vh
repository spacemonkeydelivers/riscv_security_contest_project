`ifndef SOC_HELPERS
    `define SOC_HELPERS 1

    function [31:0] log2;
        input [31:0] value;
        integer i;
        reg [31:0] j;
        begin
            j = value - 1;
            log2 = 0;
            for (i = 0; i < 31; i = i + 1)
                if (j[i]) log2 = i+1;
            end
        endfunction
`endif
