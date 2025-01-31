module MAC #
(
parameter DATA_WIDTH = 8
)
(
input clk,
input rst_n,
input En,
input Clr,
input [7:0] Ain,
input [7:0] Bin,
output [23:0] Couts,
output EnOut,
output [7:0] Bout
);

reg [DATA_WIDTH*3-1:0]sum_int;

always_ff @(posedge clk, negedge rst_n) begin 
    if (!rst_n) begin 
        sum_int = 0;
    end
    else if (Clr) begin
        sum_int = 0;
    end
    else if (En) begin
        sum_int = sum_int + (Ain * Bin);
    end
end

assign Cout = sum_int;

endmodule