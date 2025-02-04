module Minilab1 (
    

	//////////// CLOCK //////////
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,
	input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SEG7 //////////
	output	reg	     [6:0]		HEX0,
	output	reg	     [6:0]		HEX1,
	output	reg	     [6:0]		HEX2,
	output	reg	     [6:0]		HEX3,
	output	reg	     [6:0]		HEX4,
	output	reg	     [6:0]		HEX5,
	
	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		     [9:0]		SW
);

assign clk = CLOCK_50;
assign rst_n = KEY[0];

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
logic [2:0] A_read_sel;
logic [7:0] a_out [7:0];

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
logic En [8:0];
logic [7:0] Ain [7:0];
logic [7:0] Bin [8:0];
logic [23:0] Couts [7:0];
logic read_B;
logic read_A [7:0];
logic rdempty_0_ff;
logic rdempty_0_ff2;
logic rdempty_1_ff;
logic rdempty_2_ff;
logic rdempty_3_ff;
logic rdempty_4_ff;
logic rdempty_5_ff;
logic rdempty_6_ff;
logic rdempty_7_ff;

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
        .start_calc(start_calc),
        .Clr(Clr),
        .Ain(a_out[i]),
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
      .rdreq(En[z] | preread),
      .wrclk(clk),
      .wrreq(wrreq_A[z]),
      .q(a_out[z]),
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
      .rdreq(start_read),
      .wrclk(clk),
      .wrreq(wwreq_B),
      .q(Bin[0]),
      .rdempty(rdempty_B),
      .wrfull(wrfull_B)
    );
endgenerate

//read from mem write to buffer address counter
always_ff @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    rd_addr <= '0;
  end
  else if (~buf_begin_fill) begin
    rd_addr <= '0;
  end
  else if (buf_begin_fill & rd_valid) begin
    rd_addr <= rd_addr + 1'b1;
  end
end

//read from buffer write to fifo address counter
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    buf_rd_addr <= '0;
    clear_col_counter_ff <= 0;
  end
  else if (~fifo_begin_fill) begin
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
                                  ((col_counter == 7) ? datain_A[buf_rd_addr-1][56:63] :
                                  (col_counter == 6) ? datain_A[buf_rd_addr-1][48:55] : 
                                  (col_counter == 5) ? datain_A[buf_rd_addr-1][40:47] :
                                  (col_counter == 4) ? datain_A[buf_rd_addr-1][32:39] :
                                  (col_counter == 3) ? datain_A[buf_rd_addr-1][24:31] :
                                  (col_counter == 2) ? datain_A[buf_rd_addr-1][16:23] :
                                  (col_counter == 1) ? datain_A[buf_rd_addr-1][8:15] :
                                  (col_counter == 0) ? datain_A[buf_rd_addr-1][0:7] : datain_A[buf_rd_addr-1][0:7]);



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
  else if (rd_valid & (state == 1'b1)) begin
    if(rd_addr == 0) datain_B = rd_data;
    if(rd_addr == 2) datain_A[0] = rd_data;
    if(rd_addr == 3) datain_A[1] = rd_data;
    if(rd_addr == 4) datain_A[2] = rd_data;
    if(rd_addr == 5) datain_A[3] = rd_data;
    if(rd_addr == 6) datain_A[4] = rd_data;
    if(rd_addr == 7) datain_A[5] = rd_data;
    if(rd_addr == 8) datain_A[6] = rd_data;
    if(rd_addr == 9) datain_A[7] = rd_data;
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

assign buf_all_full = (rd_addr == 10) ? 1'b1 : 1'b0; //We use 9 here bc its one clock cycle after last save
assign fifo_all_full = wrfull_A[0] & wrfull_A[1] & wrfull_A[2] & wrfull_A[3] & wrfull_A[4] & wrfull_A[5] & wrfull_A[6] & wrfull_A[7] & wrfull_B;
assign fifo_all_empty = rdempty_A[0] & rdempty_A[1] & rdempty_A[2] & rdempty_A[3] & rdempty_A[4] & rdempty_A[5] & rdempty_A[6] & rdempty_A[7] & rdempty_B;

assign read_B = (~rst_n) ? 0 : (((A_read_sel == 0) & start_read));

//A read inc
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    A_read_sel <= '0;
  end
  else if(start_read) begin
    A_read_sel <= A_read_sel + 1;
  end
end

assign read_A[0] = (~rst_n) ? 0 : (start_read);
assign read_A[1] = (~rst_n) ? 0 : (start_read);
assign read_A[2] = (~rst_n) ? 0 : (start_read);
assign read_A[3] = (~rst_n) ? 0 : (start_read);
assign read_A[4] = (~rst_n) ? 0 : (start_read);
assign read_A[5] = (~rst_n) ? 0 : (start_read);
assign read_A[6] = (~rst_n) ? 0 : (start_read);
assign read_A[7] = (~rst_n) ? 0 : (start_read);

always_ff @(posedge clk) begin
  rdempty_0_ff <= rdempty_A[0];
end
always_ff @(posedge clk) begin
  rdempty_0_ff2 <= rdempty_0_ff;
end

assign En[0] = start_calc & ~rdempty_0_ff2;

// next state flop
always @(posedge clk, negedge rst_n) begin
  if (~rst_n)
    state <= IDLE;
  else
    state <= next_state;
end

always_comb begin
    preread = 0;
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
          preread = 1;
        end
        else begin
          next_state = FILL_FIFO;
          fifo_begin_fill = 1;
        end
      end
      WAIT: begin
        preread = 0;
        next_state = CALC;
        start_read = 1;
      end
      CALC: begin
        if(fifo_all_empty) begin
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

logic [23:0] macout;
logic SW_pushed;

always_comb begin
  SW_pushed = SW[0] | SW[1] | SW[2] | SW[3] | SW[4] | SW[5] | SW[6] | SW[7];
  if (SW[0])
    macout = Couts[0];
  else if (SW[1])
    macout = Couts[1];
  else if (SW[2])
    macout = Couts[2];
  else if (SW[3])
    macout = Couts[3];
  else if (SW[4])
    macout = Couts[4];
  else if (SW[5])
    macout = Couts[5];
  else if (SW[6])
    macout = Couts[6];
  else if (SW[7])
    macout = Couts[7];
  else
    macout = 0;
end


parameter HEX_0 = 7'b1000000;		// zero
parameter HEX_1 = 7'b1111001;		// one
parameter HEX_2 = 7'b0100100;		// two
parameter HEX_3 = 7'b0110000;		// three
parameter HEX_4 = 7'b0011001;		// four
parameter HEX_5 = 7'b0010010;		// five
parameter HEX_6 = 7'b0000010;		// six
parameter HEX_7 = 7'b1111000;		// seven
parameter HEX_8 = 7'b0000000;		// eight
parameter HEX_9 = 7'b0011000;		// nine
parameter HEX_10 = 7'b0001000;	// ten
parameter HEX_11 = 7'b0000011;	// eleven
parameter HEX_12 = 7'b1000110;	// twelve
parameter HEX_13 = 7'b0100001;	// thirteen
parameter HEX_14 = 7'b0000110;	// fourteen
parameter HEX_15 = 7'b0001110;	// fifteen
parameter OFF   = 7'b1111111;		// all off

always @(*) begin
  if (state == DONE & SW_pushed) begin
    case(macout[3:0])
      4'd0: HEX0 = HEX_0;
	   4'd1: HEX0 = HEX_1;
	   4'd2: HEX0 = HEX_2;
	   4'd3: HEX0 = HEX_3;
	   4'd4: HEX0 = HEX_4;
	   4'd5: HEX0 = HEX_5;
	   4'd6: HEX0 = HEX_6;
	   4'd7: HEX0 = HEX_7;
	   4'd8: HEX0 = HEX_8;
	   4'd9: HEX0 = HEX_9;
	   4'd10: HEX0 = HEX_10;
	   4'd11: HEX0 = HEX_11;
	   4'd12: HEX0 = HEX_12;
	   4'd13: HEX0 = HEX_13;
	   4'd14: HEX0 = HEX_14;
	   4'd15: HEX0 = HEX_15;
    endcase
  end
  else begin
    HEX0 = OFF;
  end
end

always @(*) begin
  if (state == DONE & SW_pushed) begin
    case(macout[7:4])
      4'd0: HEX1 = HEX_0;
	   4'd1: HEX1 = HEX_1;
	   4'd2: HEX1 = HEX_2;
	   4'd3: HEX1 = HEX_3;
	   4'd4: HEX1 = HEX_4;
	   4'd5: HEX1 = HEX_5;
	   4'd6: HEX1 = HEX_6;
	   4'd7: HEX1 = HEX_7;
	   4'd8: HEX1 = HEX_8;
	   4'd9: HEX1 = HEX_9;
	   4'd10: HEX1 = HEX_10;
	   4'd11: HEX1 = HEX_11;
	   4'd12: HEX1 = HEX_12;
	   4'd13: HEX1 = HEX_13;
	   4'd14: HEX1 = HEX_14;
	   4'd15: HEX1 = HEX_15;
    endcase
  end
  else begin
    HEX1 = OFF;
  end
end

always @(*) begin
  if (state == DONE & SW_pushed) begin
    case(macout[11:8])
      4'd0: HEX2 = HEX_0;
	   4'd1: HEX2 = HEX_1;
	   4'd2: HEX2 = HEX_2;
	   4'd3: HEX2 = HEX_3;
	   4'd4: HEX2 = HEX_4;
	   4'd5: HEX2 = HEX_5;
	   4'd6: HEX2 = HEX_6;
	   4'd7: HEX2 = HEX_7;
	   4'd8: HEX2 = HEX_8;
	   4'd9: HEX2 = HEX_9;
	   4'd10: HEX2 = HEX_10;
	   4'd11: HEX2 = HEX_11;
	   4'd12: HEX2 = HEX_12;
	   4'd13: HEX2 = HEX_13;
	   4'd14: HEX2 = HEX_14;
	   4'd15: HEX2 = HEX_15;
    endcase
  end
  else begin
    HEX2 = OFF;
  end
end

always @(*) begin
  if (state == DONE & SW_pushed) begin
    case(macout[15:12])
      4'd0: HEX3 = HEX_0;
	   4'd1: HEX3 = HEX_1;
	   4'd2: HEX3 = HEX_2;
	   4'd3: HEX3 = HEX_3;
	   4'd4: HEX3 = HEX_4;
	   4'd5: HEX3 = HEX_5;
	   4'd6: HEX3 = HEX_6;
	   4'd7: HEX3 = HEX_7;
	   4'd8: HEX3 = HEX_8;
	   4'd9: HEX3 = HEX_9;
	   4'd10: HEX3 = HEX_10;
	   4'd11: HEX3 = HEX_11;
	   4'd12: HEX3 = HEX_12;
	   4'd13: HEX3 = HEX_13;
	   4'd14: HEX3 = HEX_14;
	   4'd15: HEX3 = HEX_15;
    endcase
  end
  else begin
    HEX3 = OFF;
  end
end

always @(*) begin
  if (state == DONE & SW_pushed) begin
    case(macout[19:16])
      4'd0: HEX4 = HEX_0;
	   4'd1: HEX4 = HEX_1;
	   4'd2: HEX4 = HEX_2;
	   4'd3: HEX4 = HEX_3;
	   4'd4: HEX4 = HEX_4;
	   4'd5: HEX4 = HEX_5;
	   4'd6: HEX4 = HEX_6;
	   4'd7: HEX4 = HEX_7;
	   4'd8: HEX4 = HEX_8;
	   4'd9: HEX4 = HEX_9;
	   4'd10: HEX4 = HEX_10;
	   4'd11: HEX4 = HEX_11;
	   4'd12: HEX4 = HEX_12;
	   4'd13: HEX4 = HEX_13;
	   4'd14: HEX4 = HEX_14;
	   4'd15: HEX4 = HEX_15;
    endcase
  end
  else begin
    HEX4 = OFF;
  end
end

always @(*) begin
  if (state == DONE & SW_pushed) begin
    case(macout[23:20])
      4'd0: HEX5 = HEX_0;
	   4'd1: HEX5 = HEX_1;
	   4'd2: HEX5 = HEX_2;
	   4'd3: HEX5 = HEX_3;
	   4'd4: HEX5 = HEX_4;
	   4'd5: HEX5 = HEX_5;
	   4'd6: HEX5 = HEX_6;
	   4'd7: HEX5 = HEX_7;
	   4'd8: HEX5 = HEX_8;
	   4'd9: HEX5 = HEX_9;
	   4'd10: HEX5 = HEX_10;
	   4'd11: HEX5 = HEX_11;
	   4'd12: HEX5 = HEX_12;
	   4'd13: HEX5 = HEX_13;
	   4'd14: HEX5 = HEX_14;
	   4'd15: HEX5 = HEX_15;
    endcase
  end
  else begin
    HEX5 = OFF;
  end
end

assign LEDR = {{8{1'b0}}, state};

endmodule