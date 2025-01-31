`timescale 1 ps / 1 ps

module Minilab1_tb ();
logic clk;
logic rst_n;

Minilab1 iDUT(.clk(clk), .rst_n(rst_n));

initial begin
    clk = 0;
    rst_n = 0;

    repeat (5) @(posedge clk);

    $stop;

end

always 
    #5 clk = ~clk;


endmodule