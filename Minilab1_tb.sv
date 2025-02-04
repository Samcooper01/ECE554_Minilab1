`timescale 1 ps / 1 ps

module Minilab1_tb ();
logic clk;
logic rst_n;

localparam IDLE = 3'b000;
localparam FILL_BUF = 3'b001;
localparam FILL_FIFO = 3'b010;
localparam CALC = 3'b011;
localparam WAIT = 3'b100;
localparam DONE = 3'b101;

Minilab1 iDUT(.clk(clk), .rst_n(rst_n));

initial begin
    clk = 0;
    rst_n = 0;

    repeat (5) @(posedge clk);

    rst_n = 1;

   wait(iDUT.rd_addr == 9);

    wait(iDUT.state == FILL_FIFO);
    

    wait(iDUT.state == DONE);
    #400

    $stop;

end

always 
    #5 clk = ~clk;


endmodule