module Minilab1 (
    input wire clk,
    input wire reset_n
);

//8 MACS



//9 FIFOS
generate
  for (i=0; i<8; i=i+1) begin : fifo_gen
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