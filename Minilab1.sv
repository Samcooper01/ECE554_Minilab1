module Minilab1 (
    clk,
    rst_n
);

input clk;
input rst_n;

localparam MATRIX_COLUMNS_A = 8;

//8 MACS



//9 FIFOS
generate

  //Matrix A FIFOS
  for (i=0; i<MATRIX_COLUMNS_A; i=i+1) begin : fifo_gen
    FIFO input_fifo
    (
    .aclr(rst_n),
	  .data(),
	  .rdclk(clk),
	  .rdreq(),
	  .wrclk(clk),
	  .wrreq(),
	  .q(),
	  .rdempty(),
	  .wrfull()
    );
  end

  //MATRIX B FIFO
      FIFO input_fifo
    (
    .aclr(rst_n),
	  .data(),
	  .rdclk(clk),
	  .rdreq(),
	  .wrclk(clk),
	  .wrreq(),
	  .q(),
	  .rdempty(),
	  .wrfull()
    );


endgenerate


endmodule;