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

logic preread;

logic [0:MATRIX_COLUMNS_A] rdreq_A, wrreq_A, rdempty_A, wrfull_A;

//Matrix B Internal signals
logic [DATA_WIDTH-1:0] datain_B;
logic [DATA_WIDTH-1:0] dataout_B;

logic rdreq_B, wwreq_B, rdempty_B, wrfull_B;

//State Machine
logic [1:0] state;
logic all_full, all_empty;

//Memory Signals
logic [31:0] rd_addr;
logic rd_mem;
logic [63:0] rd_data;
logic rd_valid;
logic wait_req;


//8 MACS
logic [8:0] En;
logic [7:0] Ain [7:0];
logic [8:0] Bin [7:0];
logic Couts [23:1];

//Memory Interface
mem_wrapper iMEM( .clk(clk), 
                  .reset_n(rst_n), 
                  .address(rd_addr), 
                  .read(rd_mem), 
                  .readdata(rd_data),
                  .readdatavalid(rd_valid),
                  .waitrequest(wait_req));

genvar i;

generate
  for (i=0; i<8; i=i+1) begin : mac_gen
    MAC 
    #(
        .DATA_WIDTH(DATA_WIDTH)
    ) element_mac
    (
        .clk(clk),
        .rst_n(rst_n),
        .En(En[i]),
        .Clr(Clr),
        .Ain(Ain[i]),
        .Bin(Bin[i]),
        .Couts(Couts[i]),
        .EnOut(En[i+1]),
        .Bout(Bin[i+1])
    );
  end
endgenerate

genvar z;

//9 FIFOS
generate
  //Matrix A FIFOS
  for (z=0; z<MATRIX_COLUMNS_A; z=z+1) begin : fifo_gen
    FIFO input_fifo_A
    (
      .aclr(rst_n),
      .data(datain_A[z]),
      .rdclk(clk),
      .rdreq((En[z] | preread) & ~rdempty_A[z]),
      .wrclk(clk),
      .wrreq(wrreq_A[z]),
      .q(Ain[z]),
      .rdempty(rdempty_A[z]),
      .wrfull(wrfull_A[z])
    );
  end

  //MATRIX B FIFO
    FIFO input_fifo_B
    (
      .aclr(rst_n),
      .data(datain_B),
      .rdclk(clk),
      .rdreq((En[0] | preread) & ~rdempty_B),
      .wrclk(clk),
      .wrreq(wwreq_B),
      .q(Bin[0]),
      .rdempty(rdempty_B),
      .wrfull(wrfull_B)
    );
endgenerate

assign all_full = &wrfull_A & wrfull_B; //AND all wrfull signals from A and B TODO: MAKE SURE THIS WORKS
assign all_empty = &rdempty_A & rdempty_B; //AND all rdempty signals from A and B

//read address incremental counter
always @(posedge rd_valid or negedge rst_n) begin
  if(~rst_n) begin
    rd_addr <= '0;
  end
  else if (rd_valid) begin
    rd_addr <= rd_addr + 1'b1;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    state <= FILL;
    rd_mem <= 1'b0;
  end
  else begin
    case(state)
      FILL:
      begin
        if (preread) begin
          preread <= 1'b0;
          state <= CALC;
        end
        if (all_full) begin
          rd_mem <= 1'b0;
          wwreq_B <= 1'b0;
          for(integer p = 0; p < MATRIX_COLUMNS_A; p++) begin
            wrreq_A[p] <= 1'b0;
          end
          preread <= 1'b1;
        end
        //Fill all fifos with memory until full
        rd_mem <= 1'b1;
        wwreq_B <= 1'b0;
        for(integer p = 0; p < MATRIX_COLUMNS_A; p++) begin
          wrreq_A[p] <= 1'b0;
        end
        if (rd_valid & ~wait_req) begin
          if(rd_addr == 32'h0000) begin
            datain_B[rd_addr] <= rd_data;
            wwreq_B <= 1'b1;
          end
          else begin
            datain_A[rd_addr] = rd_data;
            wrreq_A[rd_addr] <= 1'b1;
          end
        end

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

endmodule