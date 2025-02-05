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

Minilab1 iDUT(.CLOCK_50(clk), .KEY(rst_n));

initial begin
    clk = 0;
    rst_n = 0;

    repeat (5) @(posedge clk);

    rst_n = 1;

    wait(iDUT.rd_addr == 9);

    wait(iDUT.state == FILL_FIFO);
    

    wait(iDUT.state == DONE);
    #400

    $display("Testing matrix multiplier with example memory loaded");
    $display("Test 1: First vector element expected to be 0x30C");
    if (iDUT.Couts[0] != 24'h00030C) begin
        $display("Test 1 Failed: expected 0x30C but got 0x%h", iDUT.Couts[0]);
    end
    $display("Test 1 Passed\n");

    $display("Test 2: Second vector element expected to be 0x54C");
    if (iDUT.Couts[1] != 24'h00054C) begin
        $display("Test 2 Failed: expected 0x54C but got 0x%h", iDUT.Couts[1]);
    end
    $display("Test 2 Passed\n");

    $display("Test 3: Third vector element expected to be 0x78C");
    if (iDUT.Couts[2] != 24'h00078C) begin
        $display("Test 3 Failed: expected 0x78C but got 0x%h", iDUT.Couts[2]);
    end
    $display("Test 3 Passed\n");

    $display("Test 4: Fourth vector element expected to be 0x9CC");
    if (iDUT.Couts[3] != 24'h0009CC) begin
        $display("Test 4 Failed: expected 0x9CC but got 0x%h", iDUT.Couts[3]);
    end
    $display("Test 4 Passed\n");

    $display("Test 5: Fifth vector element expected to be 0xC0C");
    if (iDUT.Couts[4] != 24'h000C0C) begin
        $display("Test 5 Failed: expected 0xC0C but got 0x%h", iDUT.Couts[4]);
    end
    $display("Test 5 Passed\n");

    $display("Test 6: Sixth vector element expected to be 0xE4C");
    if (iDUT.Couts[5] != 24'h000E4C) begin
        $display("Test 6 Failed: expected 0xE4C but got 0x%h", iDUT.Couts[5]);
    end
    $display("Test 6 Passed\n");

    $display("Test 7: Seventh vector element expected to be 0x108C");
    if (iDUT.Couts[6] != 24'h00108C) begin
        $display("Test 7 Failed: expected 0x108C but got 0x%h", iDUT.Couts[6]);
    end
    $display("Test 7 Passed\n");

    $display("Test 8: Eigth vector element expected to be 0x12CC");
    if (iDUT.Couts[7] != 24'h0012CC) begin
        $display("Test 8 Failed: expected 0x12CC but got 0x%h", iDUT.Couts[7]);
    end
    $display("Test 8 Passed\n");

    $stop();

end

always 
    #5 clk = ~clk;


endmodule