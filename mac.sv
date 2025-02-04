module MAC #
(
parameter DATA_WIDTH = 8
)
(
input logic clk,
input logic rst_n,
input logic En,
input logic start_calc,
input logic Clr,
input logic [7:0] Ain,
input logic [7:0] Bin,
output logic [23:0] Couts,
output logic EnOut,
output logic [7:0] Bout
);

reg [DATA_WIDTH*3-1:0]sum_int;

logic En_ff;

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

always_ff @(posedge clk, negedge rst_n) begin
    if(~rst_n) begin
        EnOut <= 0;
    end
    else begin
        EnOut <= En_ff;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(~rst_n) begin
        En_ff <= 0;
    end
    else begin
        En_ff <= En;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(~rst_n) begin
        Bout <= '0;
    end
    else if (~En) begin
        Bout <= Bin;
    end
end

assign Couts = sum_int;

endmodule