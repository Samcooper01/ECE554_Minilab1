module Minilab1 (
    clk,
    rst_n
);

input clk;
input rst_n;

localparam MATRIX_COLUMNS_A = 8;
localparam DATA_WIDTH = 8;

localparam FILL = 2'b00;
localparam CALC = 2'b01;
localparam DONE = 2'b00;

//Matrix A Internal signals
logic [DATA_WIDTH-1:0] datain_A [0:MATRIX_COLUMNS_A];
logic [DATA_WIDTH-1:0] dataout_A [0:MATRIX_COLUMNS_A];

logic rdreq_A, wrreq_A, rdempty_A, wrfull_A [0:MATRIX_COLUMNS_A];

//Matrix B Internal signals
logic [DATA_WIDTH-1:0] datain_B;
logic [DATA_WIDTH-1:0] dataout_B;

logic rdreq_B, wwreq_B, rdempty_B, wrfull_B;

//State Machine
logic [1:0] state;
logic all_full, all_empty;



//8 MACS
logic [8:0] En;
logic [7:0] Ain;
logic [8:0] Bin;
logic [7:0] Couts;

genvar i;

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
  for (i=0; i<MATRIX_COLUMNS_A; i=i+1) begin : fifo_gen
    FIFO input_fifo
    (
    .aclr(rst_n),
	  .data(datain_A[i]),
	  .rdclk(clk),
	  .rdreq(En[i]),
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
	  .rdreq(En[0]),
	  .wrclk(clk),
	  .wrreq(wwreq_B),
	  .q(dataout_B),
	  .rdempty(rdempty_B),
	  .wrfull(wrfull_B)
    );
endgenerate

assign all_full = &wrfull_A & wrfull_B; //AND all wrfull signals from A and B
assign all_empty = &rdempty_A & rdempty_B; //AND all rdempty signals from A and B

always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    state <= FILL;
  end
  else begin
    case(state)
      FILL:
      begin
        if (all_full) begin
          state <= CALC;
        end
        //Fill all fifos with memory until full

      end
      CALC:
      begin
        if (all_empty) begin
          state <= DONE;
        end
        //Read fifos until all values have been read

      end
      DONE:
      begin
        //Display result onto the LEDS

      end
    endcase
  end

end

endmodule;