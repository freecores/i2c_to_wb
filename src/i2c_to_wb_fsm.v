// --------------------------------------------------------------------
//
// --------------------------------------------------------------------


`include "timescale.v"


module
  i2c_to_wb_fsm
  (
    input         i2c_data,
    input         i2c_data_rise,
    input         i2c_data_fall,

    input         i2c_clk,
    input         i2c_clk_rise,
    input         i2c_clk_fall,
    
    input         i2c_bit_7,
    output        i2c_ack_done, 
    
    output        tip_addr_byte, 
//     output        tip_byte, 
    output        tip_read_byte, 
    output        tip_write_byte, 
    output        tip_wr_ack, 
    output        tip_rd_ack, 
    output        tip_addr_ack, 
//     output        tip_ack, 
//     output        tip_write, 
//     output        tip_read, 
    
    output  [7:0] state_out,
    
    input         wb_clk_i, 
    input         wb_rst_i  
  );
  
  // --------------------------------------------------------------------
  //  wires
  wire xmt_byte_done;
  
//   wire i2c_read  = 1'b0;
//   wire i2c_ack_done;
  wire i2c_address_hit = 1'b1;
  
  wire tip_ack;
  

  // --------------------------------------------------------------------
  //  start & stop 
  
  wire start_detected = i2c_data_fall & i2c_clk;
  wire stop_detected  = i2c_data_rise & i2c_clk;
  
  
  // --------------------------------------------------------------------
  //  state machine

  localparam   STATE_IDLE       = 8'b00000001;
  localparam   STATE_ADDR_BYTE  = 8'b00000010;
  localparam   STATE_ADDR_ACK   = 8'b00000100;
  localparam   STATE_WRITE      = 8'b00001000;
  localparam   STATE_WR_ACK     = 8'b00010000;
  localparam   STATE_READ       = 8'b00100000;
  localparam   STATE_RD_ACK     = 8'b01000000;
  localparam   STATE_ERROR      = 8'b10000000;

  reg [7:0] state;
  reg [7:0] next_state;
  
  always @(posedge wb_clk_i or posedge wb_rst_i)
    if(wb_rst_i)
      state <= STATE_IDLE;
    else
      state <= next_state;

  always @(*)
    case( state )
      STATE_IDLE:       if( start_detected )
                          next_state = STATE_ADDR_BYTE;
                        else
                          next_state = STATE_IDLE;                              
                            
      STATE_ADDR_BYTE:  if( xmt_byte_done )
                          if( i2c_address_hit )
                            next_state = STATE_ADDR_ACK;
                          else
                            next_state = STATE_IDLE;
                        else if( start_detected | stop_detected )
                          next_state = STATE_ERROR;
                        else  
                          next_state = STATE_ADDR_BYTE;
                          
      STATE_ADDR_ACK:   if( i2c_ack_done )
                          if( i2c_bit_7 )
                            next_state = STATE_READ;
                          else
                            next_state = STATE_WRITE;
                        else if( start_detected | stop_detected )
                          next_state = STATE_ERROR;
                        else
                          next_state = STATE_ADDR_ACK;
                            
      STATE_WRITE:      if( xmt_byte_done )
                          next_state = STATE_WR_ACK;
                        else if( start_detected )
                          next_state = STATE_ADDR_BYTE;
                        else if( stop_detected )
                          next_state = STATE_IDLE;
                        else
                          next_state = STATE_WRITE;
                            
      STATE_WR_ACK:     if( i2c_ack_done )
                          next_state = STATE_WRITE;  
                        else if( start_detected | stop_detected )
                          next_state = STATE_ERROR;
                        else
                          next_state = STATE_WR_ACK;
                            
      STATE_READ:       if( xmt_byte_done )
                          next_state = STATE_RD_ACK;
                        else if( start_detected )
                          next_state = STATE_ADDR_BYTE;
                        else if( stop_detected )
                          next_state = STATE_IDLE;
                        else
                          next_state = STATE_READ;
                            
      STATE_RD_ACK:     if( i2c_ack_done )
                          next_state = STATE_READ;  
                        else if( start_detected | stop_detected )
                          next_state = STATE_ERROR;
                        else
                          next_state = STATE_RD_ACK;
                            
      STATE_ERROR:      next_state = STATE_IDLE;
                        
      default:          next_state = STATE_ERROR;
    endcase
    
    
  // --------------------------------------------------------------------
  //  bit counter 
  reg [3:0] bit_count;
  
  assign  xmt_byte_done = (bit_count == 4'h7) & i2c_clk_rise; 
  assign  tip_ack       = (bit_count == 4'h8);
  assign  i2c_ack_done  = tip_ack & i2c_clk_rise;
    
  always @(posedge wb_clk_i)
    if( wb_rst_i | i2c_ack_done | start_detected )
      bit_count <= 4'hf;
    else if( i2c_clk_fall )
      bit_count <= bit_count + 1;
  
    
// --------------------------------------------------------------------
//  outputs
    
  assign state_out = state;
    
  assign  tip_addr_byte   = (state == STATE_ADDR_BYTE);
  assign  tip_addr_ack    = (state == STATE_ADDR_ACK);
  assign  tip_read_byte   = (state == STATE_READ);
  assign  tip_write_byte  = tip_addr_byte               | (state == STATE_WRITE);
  assign  tip_wr_ack      = tip_addr_ack                | (state == STATE_WR_ACK);
  assign  tip_rd_ack      = (state == STATE_RD_ACK);
//   assign  tip_byte        = tip_write_byte              | tip_read_byte;
//   assign  tip_write       = tip_write_byte              | tip_wr_ack;
//   assign  tip_read        = tip_read_byte               | tip_rd_ack;
  
endmodule
  
  

