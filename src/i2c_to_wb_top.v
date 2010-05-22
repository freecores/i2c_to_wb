// --------------------------------------------------------------------
//
// --------------------------------------------------------------------


`include "timescale.v"


module
  i2c_to_wb_top
  #(
    parameter DW = 32,
    parameter AW = 32
  ) 
  (
    input               i2c_data_in,
    input               i2c_clk_in,
    output              i2c_data_out,
    output              i2c_clk_out,
    output              i2c_data_oe,
    output              i2c_clk_oe,

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
  //  bit counter 
  reg [3:0] bit_count;
  wire ack_done = (bit_count > 4'h8) & gf_i2c_clk_in_rise;
  
  always @(posedge wb_clk_i or posedge wb_rst_i)
    if( wb_rst_i | ack_done )
      bit_count <= 4'h0;
    else if( gf_i2c_clk_in_fall )
      bit_count <= bit_count + 1;
          
        
  // --------------------------------------------------------------------
  //  start & stop 
  
  reg gf_i2c_data_in_fall_reg;
  always @(posedge wb_clk_i)
    gf_i2c_data_in_fall_reg <= gf_i2c_data_in_fall;
  
  reg gf_i2c_data_in_rise_reg;
  always @(posedge wb_clk_i)
    gf_i2c_data_in_rise_reg <= gf_i2c_data_in_rise;
  
  wire start_detected = gf_i2c_data_in_fall_reg & gf_i2c_clk_in;
  wire stop_detected  = gf_i2c_data_in_rise_reg & gf_i2c_clk_in;
  
  
  // --------------------------------------------------------------------
  //  transmition in progress 
  
  reg tip_slave_address;
  
  always @(posedge wb_clk_i)
    if( ack_done | wb_rst_i )
      tip_slave_address <= 1'b0;
    else if( start_detected )
      tip_slave_address <= 1'b1;
  
  reg tip;
  
  always @(posedge wb_clk_i)
    if( wb_rst_i )
      tip <= 0;
    else if( start_detected | stop_detected )
      tip <= start_detected;
      
  wire bit_ack_detected = (bit_count == 4'h9) & tip;
  
  
  // --------------------------------------------------------------------
  //  ack flop 
  reg ack_bit_r;
  
  always @(posedge wb_clk_i)
    if( wb_rst_i )
      ack_bit_r <= 1'b0;
    else if( bit_ack_detected & gf_i2c_clk_in_fall )
      ack_bit_r <= i2c_data_in;
      
    
  // --------------------------------------------------------------------
  //  outputs  
  assign i2c_data_out = 1'b1;
  assign i2c_clk_out  = 1'b1;
  assign i2c_data_oe  = 1'b0;
  assign i2c_clk_oe   = 1'b0;

  
endmodule

