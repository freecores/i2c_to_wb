// --------------------------------------------------------------------
//
// --------------------------------------------------------------------


`include "timescale.v"


module tb_dut(
                input tb_clk,
                input tb_rst
              );


  // --------------------------------------------------------------------
  // test bench variables
  reg test_it;
  

  // --------------------------------------------------------------------
  // wires
  wire i2c_data;
  wire i2c_clk;
    
  
  // --------------------------------------------------------------------
  //  async_mem_master
	pullup p1(i2c_data); // pullup scl line
	pullup p2(i2c_clk); // pullup sda line
  
  i2c_master_model
    i2c(  
      .i2c_data(i2c_data),
      .i2c_clk(i2c_clk)
    );
    
    
  // --------------------------------------------------------------------
  //  i2c_to_wb_top
  wire i2c_data_out;
  wire i2c_clk_out;
  wire i2c_data_oe;
  wire i2c_clk_oe;
  wire [31:0] wb_data_i = 32'ha5a5a5a5;
  wire [31:0] wb_data_o;
  wire [31:0] wb_addr_o;
  wire [3:0] wb_sel_o;
  wire wb_we_o;
  wire wb_cyc_o;
  wire wb_stb_o;
  wire wb_ack_i = 1'b1;
  wire wb_err_i = 1'b0;
  wire wb_rty_i = 1'b0;
  
  // tristate buffers
  assign i2c_data = i2c_data_oe ? i2c_data_out  : 1'bz;
  assign i2c_clk  = i2c_clk_oe  ? i2c_clk_out   : 1'bz;
    
  i2c_to_wb_top
    i_i2c_to_wb_top(
      .i2c_data_in(i2c_data),
      .i2c_clk_in(i2c_clk),
      .i2c_data_out(i2c_data_out),
      .i2c_clk_out(i2c_clk_out),
      .i2c_data_oe(i2c_data_oe),
      .i2c_clk_oe(i2c_clk_oe),
      
      .thd_dat(4'h8),
  
      .wb_data_i(wb_data_i),
      .wb_data_o(wb_data_o),
      .wb_addr_o(wb_addr_o),
      .wb_sel_o(wb_sel_o),
      .wb_we_o(wb_we_o),
      .wb_cyc_o(wb_cyc_o),
      .wb_stb_o(wb_stb_o),
      .wb_ack_i(wb_ack_i),
      .wb_err_i(wb_err_i),
      .wb_rty_i(wb_rty_i),
          
      .wb_clk_i(tb_clk),
      .wb_rst_i(tb_rst)
  );
  
  
  // --------------------------------------------------------------------
  //  glitch_generator 
  glitch_generator i_g1( i2c_data );
  glitch_generator i_g2( i2c_clk );
  
  
  // --------------------------------------------------------------------
  //  outputs
  
  
  
endmodule

