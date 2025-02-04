module Minilab1 (
    clk,
    rst_n
);

input clk;
input rst_n;

localparam MATRIX_COLUMNS_A = 8;
localparam DATA_WIDTH = 8;

localparam IDLE = 3'b000;
localparam FILL_BUF = 3'b001;
localparam FILL_FIFO = 3'b010;
localparam CALC = 3'b011;
localparam WAIT = 3'b100;
localparam DONE = 3'b101;

//A and B buffers to hold parsed data
logic [0:63] datain_A [0:7];
logic [0:63] datain_B;
logic [4:0] buf_rd_addr;

//FIFO Signals
logic [7:0] datain;
logic wrreq_A  [0:7];
logic wwreq_B;
logic [3:0] a_col_sel;
logic [3:0] b_col_sel;
logic [3:0] col_counter;
logic clear_col_counter;
logic clear_col_counter_ff;
logic buffer_a_or_b;

logic preread;

logic [0:MATRIX_COLUMNS_A-1] rdreq_A, rdempty_A, wrfull_A;

logic rdreq_B, rdempty_B, wrfull_B;

//State Machine
logic [2:0] state, next_state;
logic all_full, all_empty;
logic buf_begin_fill;
logic buf_all_full;
logic fifo_begin_fill;
logic fifo_all_full;
logic start_calc;
logic start_read;

//Memory Signals
logic [31:0] rd_addr;
logic rd_mem;
logic [63:0] rd_data;
logic rd_valid;
logic wait_req;

//8 MACS
logic [7:0] En;
logic [7:0] Ain [7:0];
logic [7:0] Bin [7:0];
logic [23:0] Couts [7:0];
logic read_B;
logic read_A [7:0];

//Memory Interface
mem_wrapper iMEM( .clk(clk), 
                  .reset_n(rst_n), 
                  .address(rd_addr), 
                  .read(buf_begin_fill), 
                  .readdata(rd_data),
                  .readdatavalid(rd_valid),
                  .waitrequest(wait_req));

genvar i;

//MAC Interface
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

//FIFO Interface
generate
  //Matrix A FIFOS
  for (z=0; z<MATRIX_COLUMNS_A; z=z+1) begin : fifo_gen
    FIFO input_fifo_A
    (
      .aclr(~rst_n),
      .data(datain),
      .rdclk(clk),
      .rdreq(read_A[z] | preread),
      .wrclk(clk),
      .wrreq(wrreq_A[z]),
      .q(),
      .rdempty(rdempty_A[z]),
      .wrfull(wrfull_A[z])
    );
  end
  //MATRIX B FIFO
    FIFO input_fifo_B
    (
      .aclr(~rst_n),
      .data(datain),
      .rdclk(clk),
      .rdreq(read_B | preread),
      .wrclk(clk),
      .wrreq(wwreq_B),
      .q(),
      .rdempty(rdempty_B),
      .wrfull(wrfull_B)
    );
endgenerate

//read from mem write to buffer address counter
always @(posedge clk or negedge rst_n) begin
  if(~rst_n | ~buf_begin_fill) begin
    rd_addr <= '0;
  end
  else if (buf_begin_fill & rd_valid) begin
    rd_addr <= rd_addr + 1'b1;
  end
end

//read from buffer write to fifo address counter
always @(posedge clk or negedge rst_n) begin
  if(~rst_n | ~fifo_begin_fill) begin
    buf_rd_addr <= '0;
    clear_col_counter_ff <= 0;
  end
  else if (fifo_begin_fill & (col_counter == 7)) begin
    buf_rd_addr <= buf_rd_addr + 1'b1;
    clear_col_counter_ff <= 1;
  end
  else if(fifo_begin_fill) begin
    clear_col_counter_ff <= 0;
  end
end

assign clear_col_counter = (~rst_n | ~fifo_begin_fill) ? 0 : (fifo_begin_fill & (col_counter == 7));

//column counter for fifo
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    col_counter <= 0;
  end
  else if (fifo_begin_fill & ~clear_col_counter) begin
    col_counter <= col_counter + 1'b1;
  end
  else if(fifo_begin_fill & clear_col_counter) begin
    col_counter <= 0;
  end
end

assign buffer_a_or_b = (buf_rd_addr == 0);

//if buffer_a_or_b == 1 then buffer b is select else buffer a is select
assign datain = (buffer_a_or_b) ? ((col_counter == 7) ? datain_B[56:63] :
                                  (col_counter == 6) ? datain_B[48:55] : 
                                  (col_counter == 5) ? datain_B[40:47] :
                                  (col_counter == 4) ? datain_B[32:39] :
                                  (col_counter == 3) ? datain_B[24:31] :
                                  (col_counter == 2) ? datain_B[16:23] :
                                  (col_counter == 1) ? datain_B[8:15] :
                                  (col_counter == 0) ? datain_B[0:7] : datain_B[0:7]) :
                                  ((col_counter == 7) ? datain_A[buf_rd_addr][56:63] :
                                  (col_counter == 6) ? datain_A[buf_rd_addr][48:55] : 
                                  (col_counter == 5) ? datain_A[buf_rd_addr][40:47] :
                                  (col_counter == 4) ? datain_A[buf_rd_addr][32:39] :
                                  (col_counter == 3) ? datain_A[buf_rd_addr][24:31] :
                                  (col_counter == 2) ? datain_A[buf_rd_addr][16:23] :
                                  (col_counter == 1) ? datain_A[buf_rd_addr][8:15] :
                                  (col_counter == 0) ? datain_A[buf_rd_addr][0:7] : datain_A[buf_rd_addr][0:7]);



//write fifo EN flop
assign wwreq_B = (~rst_n) ? 0 : ((buf_rd_addr == 0) & fifo_begin_fill);
assign wrreq_A[0] = (~rst_n) ? 0 : ((buf_rd_addr == 1) & fifo_begin_fill);
assign wrreq_A[1] = (~rst_n) ? 0 : ((buf_rd_addr == 2) & fifo_begin_fill);
assign wrreq_A[2] = (~rst_n) ? 0 : ((buf_rd_addr == 3) & fifo_begin_fill);
assign wrreq_A[3] = (~rst_n) ? 0 : ((buf_rd_addr == 4) & fifo_begin_fill);
assign wrreq_A[4] = (~rst_n) ? 0 : ((buf_rd_addr == 5) & fifo_begin_fill);
assign wrreq_A[5] = (~rst_n) ? 0 : ((buf_rd_addr == 6) & fifo_begin_fill);
assign wrreq_A[6] = (~rst_n) ? 0 : ((buf_rd_addr == 7) & fifo_begin_fill);
assign wrreq_A[7] = (~rst_n) ? 0 : ((buf_rd_addr == 8) & fifo_begin_fill);

//Data store flop
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    datain_B <= '0;
    datain_A[0] <= '0;
    datain_A[1] <= '0;
    datain_A[2] <= '0;
    datain_A[3] <= '0;
    datain_A[4] <= '0;
    datain_A[5] <= '0;
    datain_A[6] <= '0;
    datain_A[7] <= '0;
  end
  else if (rd_valid) begin
    if(rd_addr == 0) datain_B = rd_data;
    if(rd_addr == 1) datain_A[0] = rd_data;
    if(rd_addr == 2) datain_A[1] = rd_data;
    if(rd_addr == 3) datain_A[2] = rd_data;
    if(rd_addr == 4) datain_A[3] = rd_data;
    if(rd_addr == 5) datain_A[4] = rd_data;
    if(rd_addr == 6) datain_A[5] = rd_data;
    if(rd_addr == 7) datain_A[6] = rd_data;
    if(rd_addr == 8) datain_A[7] = rd_data;
  end
  else begin
    datain_B <= datain_B;
    datain_A[0] <= datain_A[0];
    datain_A[1] <= datain_A[1];
    datain_A[2] <= datain_A[2];
    datain_A[3] <= datain_A[3];
    datain_A[4] <= datain_A[4];
    datain_A[5] <= datain_A[5];
    datain_A[6] <= datain_A[6];
    datain_A[7] <= datain_A[7];
  end
end

assign buf_all_full = (rd_addr == 9) ? 1'b1 : 1'b0; //We use 9 here bc its one clock cycle after last save
assign fifo_all_full = wrfull_A[0] & wrfull_A[1] & wrfull_A[2] & wrfull_A[3] & wrfull_A[4] & wrfull_A[5] & wrfull_A[6] & wrfull_A[7] & wrfull_B;

//B read inc
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    read_B <= 0;
  end
end

//A read inc
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    read_A[0] = 0;
    read_A[1] = 0;
    read_A[2] = 0;
    read_A[3] = 0;
    read_A[4] = 0;
    read_A[5] = 0;
    read_A[7] = 0;
  end
end

// next state flop
always @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    state <= IDLE;
  else
    state <= next_state;
end

always_comb begin
    buf_begin_fill = 0;
    fifo_begin_fill= 0;
    start_calc = 0;
    start_read = 0;
    next_state = state;

    case(state)
      IDLE: begin
        if(rst_n) begin
          next_state = FILL_BUF;
        end
        else begin
          next_state = IDLE;
        end
      end
      FILL_BUF: begin
        if(buf_all_full) begin
          next_state = FILL_FIFO;
        end
        else begin
          next_state = FILL_BUF;
          buf_begin_fill = 1;
        end
      end
      FILL_FIFO: begin
        if(fifo_all_full) begin
          next_state = WAIT;
        end
        else begin
          next_state = FILL_FIFO;
          fifo_begin_fill = 1;
        end
      end
      WAIT: begin
        next_state = CALC;
        start_read = 1;
      end
      CALC: begin
        if(all_empty) begin
          next_state = DONE;
        end
        else begin
          next_state = WAIT;
          start_calc = 1;
        end
      end
      DONE: begin
      //Display result onto the LEDS
        

      end
      default: begin
				next_state = IDLE;
			end
    endcase
end


endmodule