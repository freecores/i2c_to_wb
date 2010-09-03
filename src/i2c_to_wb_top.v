// --------------------------------------------------------------------
//
// --------------------------------------------------------------------


`include "timescale.v"


module
  i2c_to_wb_top
  #(
    parameter DW = 32,
    parameter AW = 8
  ) 
  (
    input               i2c_data_in,
    input               i2c_clk_in,
    output              i2c_data_out,
    output              i2c_clk_out,
    output              i2c_data_oe,
    output              i2c_clk_oe,
    
    input   [3:0]       thd_dat,

    input   [(DW-1):0]  wb_data_i,
    output  [(DW-1):0]  wb_data_o,
    output  [(AW-1):0]  wb_addr_o,
    output  [3:0]       wb_sel_o,
    output              wb_we_o,
    output              wb_cyc_o,
    output              wb_stb_o,
    input               wb_ack_i,
    input               wb_err_i,
    input               wb_rty_i,
    
    input               wb_clk_i,
    input               wb_rst_i  
  );
  
  // --------------------------------------------------------------------
  //  wires
//   wire tip_byte;
  wire tip_addr_byte; 
  wire tip_read_byte; 
  wire tip_write_byte; 
  wire tip_wr_ack;
  wire tip_rd_ack;
  wire tip_addr_ack;
//   wire tip_ack;
//   wire tip_write;
//   wire tip_read;
  
  wire i2c_ack_out = 1'b0;
  wire i2c_ack_done;
  
  // --------------------------------------------------------------------
  //  glitch filter
  
  wire gf_i2c_data_in;
  wire gf_i2c_data_in_rise;
  wire gf_i2c_data_in_fall;
  
  glitch_filter
    i_gf_i2c_data_in(
    .in(i2c_data_in),
    .out(gf_i2c_data_in),
    
    .rise(gf_i2c_data_in_rise),
    .fall(gf_i2c_data_in_fall),
    
    .clk(wb_clk_i),
    .rst(wb_rst_i)  
  );
  
  wire gf_i2c_clk_in;
  wire gf_i2c_clk_in_rise;
  wire gf_i2c_clk_in_fall;
  
  glitch_filter
    i_gf_i2c_clk_in(
    .in(i2c_clk_in),
    .out(gf_i2c_clk_in),
    
    .rise(gf_i2c_clk_in_rise),
    .fall(gf_i2c_clk_in_fall),
    
    .clk(wb_clk_i),
    .rst(wb_rst_i)  
  );
  
  
  // --------------------------------------------------------------------
  //  i2c data 
  
  reg  [8:0]  i2c_data_in_r;    // add throw away bit for serial_out
  reg         parallel_load_r;
  wire        parallel_load       = ~parallel_load_r & tip_read_byte;
  wire [7:0]  parallel_load_data  = 8'h11;
  wire        serial_out          = i2c_data_in_r[8];
  
  always @(posedge wb_clk_i)
    parallel_load_r <= tip_read_byte;
  
  always @(posedge wb_clk_i)
    if( parallel_load )
      i2c_data_in_r[7:0] <= parallel_load_data;
    else if( (tip_write_byte & gf_i2c_clk_in_rise) | (tip_read_byte & gf_i2c_clk_in_fall) )
      i2c_data_in_r <= {i2c_data_in_r[7:0], gf_i2c_data_in};
      
      
  // --------------------------------------------------------------------
  //  wishbone stuff 
  
  reg [7:0] i2c_address_r;    
  always @(posedge wb_clk_i)
    if( tip_addr_ack )
      i2c_address_r <= 8'h00;
    else if( i2c_ack_done )  
      i2c_address_r <= i2c_address_r + 1;
  

  // --------------------------------------------------------------------
  //  state machine   
  i2c_to_wb_fsm
    i_i2c_to_wb_fsm
    (
      .i2c_data(gf_i2c_data_in),
      .i2c_data_rise(gf_i2c_data_in_rise),
      .i2c_data_fall(gf_i2c_data_in_fall),
  
      .i2c_clk(gf_i2c_clk_in),
      .i2c_clk_rise(gf_i2c_clk_in_rise),
      .i2c_clk_fall(gf_i2c_clk_in_fall),
      
      .i2c_bit_7(i2c_data_in_r[7]),
      .i2c_ack_done(i2c_ack_done),
      
      .tip_addr_byte(tip_addr_byte),
//       .tip_byte(tip_byte), 
      .tip_read_byte(tip_read_byte),
      .tip_write_byte(tip_write_byte),
      .tip_wr_ack(tip_wr_ack), 
      .tip_rd_ack(tip_rd_ack), 
      .tip_addr_ack(tip_addr_ack), 
//       .tip_ack(tip_ack), 
//       .tip_write(tip_write), 
//       .tip_read(tip_read), 
    
      .state_out(),
      
      .wb_clk_i(wb_clk_i),
      .wb_rst_i(wb_rst_i)  
    );
  
    
  // --------------------------------------------------------------------
  //  i2c_data out sync
  
  reg i2c_data_oe_r;
  always @(posedge wb_clk_i)
    if( wb_rst_i )
      i2c_data_oe_r <= 1'b0;
    else if( gf_i2c_clk_in_fall )
      i2c_data_oe_r <= tip_read_byte | tip_wr_ack;
    
  reg i2c_data_mux_select_r;
  always @(posedge wb_clk_i)
    if( gf_i2c_clk_in_fall )
      i2c_data_mux_select_r <= tip_wr_ack;
    
    
  // --------------------------------------------------------------------
  //  outputs  
  
  assign i2c_data_out = i2c_data_mux_select_r ? i2c_ack_out : serial_out;
  assign i2c_data_oe  = i2c_data_oe_r;
  assign i2c_clk_out  = 1'b1;
  assign i2c_clk_oe   = 1'b0;
  
  assign wb_cyc_o       = tip_wr_ack | tip_rd_ack;
  assign wb_addr_o[7:0] = i2c_address_r;
  assign wb_we_o        = tip_wr_ack;

  
endmodule

