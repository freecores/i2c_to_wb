// --------------------------------------------------------------------
//
// --------------------------------------------------------------------

`timescale 1ns/10ps


module 
  i2c_master_model
  #(
    parameter LOG_LEVEL = 3
  ) 
  (  
    inout i2c_data,
    inout i2c_clk
  );
  
  localparam tBUF     = 4700;
  localparam tSU_STA  = 4700;
  localparam tSU_DAT  = 250;
  localparam tHD_DAT  = 0; 
  localparam tHD_STA  = 4000; 
  localparam tLOW     = 4700; 
  localparam tHIGH    = 4000; 
  
  // --------------------------------------------------------------------
  //  wires & regs
  wire i2c_data_in = i2c_data;
  wire i2c_clk_in  = i2c_clk;
  
  reg i2c_data_oe;
  reg i2c_clk_oe;
  reg i2c_data_out;
  reg i2c_clk_out;
  
  reg i2c_ack_in;
  
  
  // --------------------------------------------------------------------
  //  init 
  initial
    begin
      i2c_data_oe   = 1'b0;
      i2c_clk_oe    = 1'b0;
      i2c_data_out  = 1'b1;
      i2c_clk_out   = 1'b1;
    end
    
  
  // --------------------------------------------------------------------
  //  start
  task start; 
    begin
    
      if( LOG_LEVEL > 2 )
        $display( "###- %m: I2C start at time %t. ", $time );
      
      i2c_data_out  = 1'b1;
      i2c_clk_out   = 1'b1;
      
      #tBUF;
      
      i2c_data_oe = 1'b1;
      i2c_clk_oe  = 1'b1;
      
      if( i2c_data != 1'b1 )
        begin
          #tHD_DAT;
          i2c_data_out = 1'b1;
        end
        
      if( i2c_clk != 1'b1 )
        begin
          i2c_clk_out = 1'b1;
          #tSU_DAT;
        end
        
      #tSU_STA;  
      i2c_data_out = 1'b0; 
         
    end    
  endtask
  

  // --------------------------------------------------------------------
  //  stop
  task stop; 
    begin
    
      if( LOG_LEVEL > 2 )
        $display( "###- %m: I2C stop at time %t. ", $time );
    
      if( i2c_data != 1'b0 )
        begin
          #tHD_DAT;
          i2c_data_out = 1'b0;
        end
        
      if( i2c_clk != 1'b1 )
        begin
          i2c_clk_out = 1'b1;
          #tSU_DAT;
        end
      
      i2c_data_out  = 1'b1;
      i2c_clk_out   = 1'b1;
          
      i2c_data_oe = 1'b0;
      i2c_clk_oe  = 1'b0;
         
    end    
  endtask
  

  // --------------------------------------------------------------------
  //  write_bit
  task write_bit;
    input bit;
      begin
      
        #tHD_DAT;
        i2c_data_oe = 1'b1;
        i2c_data_out = bit;
        #tLOW;
        
        i2c_clk_out = 1'b1;
        #tHIGH;
        i2c_clk_out = 1'b0;
      
        
      end    
  endtask

            
  // --------------------------------------------------------------------
  //  write_byte
  task write_byte;
    input [7:0]  data;
      begin
      
        if( LOG_LEVEL > 2 )
          $display( "###- %m: I2C write 0x%h at time %t. ", data, $time );
          
        #tHD_STA;
        
        i2c_clk_out = 1'b0;
        
        write_bit( data[7] );
        write_bit( data[6] );
        write_bit( data[5] );
        write_bit( data[4] );
        write_bit( data[3] );
        write_bit( data[2] );
        write_bit( data[1] );
        write_bit( data[0] );
        
        #tHD_DAT;
        i2c_data_oe = 1'b0;
        #tLOW;
        
        i2c_clk_out = 1'b1;
        
        i2c_ack_in = i2c_data;
        
        if( LOG_LEVEL > 2 )
          if( i2c_data )
            $display( "###- %m: I2C NACK at time %t. ", $time );
          else  
            $display( "###- %m: I2C ACK at time %t. ", $time );
            
        #tHIGH;
                        
      end    
  endtask

  
  // --------------------------------------------------------------------
  //  read_bit
  reg [7:0] i2c_buffer_in;
  
  task read_bit;
    input [3:0] bit;
      begin
      
        i2c_data_oe = 1'b0;
        
        #tHD_DAT;
        i2c_buffer_in[bit] = i2c_data_in;
        #tLOW;
        
        i2c_clk_out = 1'b1;
        #tHIGH;
        i2c_clk_out = 1'b0;
      
        
      end    
  endtask

  
  // --------------------------------------------------------------------
  //  read_byte
  task read_byte;
      begin
          
        #tHD_STA;
        
        i2c_clk_out = 1'b0;
        i2c_data_oe = 1'b0;
        
        read_bit( 7 );
        read_bit( 6 );
        read_bit( 5 );
        read_bit( 4 );
        read_bit( 3 );
        read_bit( 2 );
        read_bit( 1 );
        read_bit( 0 );
        
        i2c_data_oe = 1'b1;
        #tHD_DAT;
        i2c_data_out = 1'b0;
        #(tLOW - tHD_DAT);
        i2c_clk_out = 1'b1;
        
        if( LOG_LEVEL > 2 )
          $display( "###- %m: I2C read 0x%h at time %t. ", i2c_buffer_in, $time );
          
      end    
  endtask
      
            
  // --------------------------------------------------------------------
  //  outputs  
  assign i2c_data = i2c_data_oe ? i2c_data_out  : 1'bz;
  assign i2c_clk  = i2c_clk_oe  ? i2c_clk_out   : 1'bz;


endmodule

