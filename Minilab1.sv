module Minilab1 (
    clk,
    rst_n
);

input clk;
input rst_n;

localparam MATRIX_COLUMNS_A = 8;
localparam DATA_WIDTH = 8;

//Matrix A Internal signals
logic [DATA_WIDTH-1:0] datain_A [0:MATRIX_COLUMNS_A];
logic [DATA_WIDTH-1:0] dataout_A [0:MATRIX_COLUMNS_A];

logic rdreq_A, wrreq_A, rdempty_A, wrfull_A [0:MATRIX_COLUMNS_A];

//Matrix B Internal signals
logic [DATA_WIDTH-1:0] datain_B;
logic [DATA_WIDTH-1:0] dataout_B;

logic rdreq_B, wwreq_B, rdempty_B, wrfull_B;


//8 MACS



//9 FIFOS
generate

  //Matrix A FIFOS
  for (integer i=0; i<MATRIX_COLUMNS_A; i=i+1) begin : fifo_gen
    FIFO input_fifo
    (
    .aclr(rst_n),
	  .data(datain_A[i]),
	  .rdclk(clk),
	  .rdreq(rdreq_A[i]),
	  .wrclk(clk),
	  .wrreq(wrreq_A[i]),
	  .q(dataout_A[i]),
	  .rdempty(rdempty_A[i]),
	  .wrfull(wrfull_A[i])
    );
  end

  //MATRIX B FIFO
      FIFO input_fifo
    (
    .aclr(rst_n),
	  .data(datain_B),
	  .rdclk(clk),
	  .rdreq(rdreq_B),
	  .wrclk(clk),
	  .wrreq(wwreq_B),
	  .q(dataout_B),
	  .rdempty(rdempty_B),
	  .wrfull(wrfull_B)
    );


endgenerate


endmodule;