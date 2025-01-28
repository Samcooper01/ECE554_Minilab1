module Minilab1 (
    input wire clk,
    input wire rst_n
);

//8 MACS
logic [8:0] En;
logic [7:0] Ain;
logic [8:0] Bin;
logic [7:0] Couts;
generate
  for (i=0; i<8; i=i+1) begin : fifo_gen
    MAC 
    #(
        .DATA_WIDTH(DATA_WIDTH)
    ) element_mac
    (
        .clk(clk),
        .rst_n(rst_n),
        .En(En[7:0]),
        .Clr(Clr),
        .Ain(Ain[7:0]),
        .Bin(Bin[7:0]),
        .Couts(Couts[7:0]),
        .EnOut(EnOut[8:1]),
        .Bout(Bin[8:1]),
    );
  end
endgenerate

//9 FIFOS
generate
  for (i=0; i<9; i=i+1) begin : fifo_gen
    FIFO
    #(
    .DEPTH(DEPTH),
    .DATA_WIDTH(DATA_WIDTH)
    ) input_fifo
    (
    .clk(CLOCK_50),
    .rst_n(rst_n),
    .rden(rden[i]),
    .wren(wren[i]),
    .i_data(datain[i]),
    .o_data(dataout[i]),
    .full(full[i]),
    .empty(empty[i])
    );
  end
endgenerate


endmodule;