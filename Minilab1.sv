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

  //Matrix A FIFOS
  for (integer i=0; i<MATRIX_COLUMNS_A; i=i+1) begin : fifo_gen
    FIFO input_fifo_A
    (
      .aclr(rst_n),
      .data(datain_A[i]),
      .rdclk(clk),
      .rdreq(En[i] | preread),
      .wrclk(clk),
      .wrreq(wrreq_A[i]),
      .q(Ain[i]),
      .rdempty(rdempty_A[i]),
      .wrfull(wrfull_A[i])
    );
  end

  //MATRIX B FIFO
    FIFO input_fifo_B
    (
      .aclr(rst_n),
      .data(datain_B),
      .rdclk(clk),
      .rdreq(En[0] | preread),
      .wrclk(clk),
      .wrreq(wwreq_B),
      .q(Bin[0]),
      .rdempty(rdempty_B),
      .wrfull(wrfull_B)
    );


endgenerate

endmodule;