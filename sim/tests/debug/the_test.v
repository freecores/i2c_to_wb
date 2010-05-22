// --------------------------------------------------------------------
//
// --------------------------------------------------------------------

`timescale 1ns/10ps


module the_test(
                input tb_clk,
                input tb_rst
              );


  task run_the_test;
    begin
    
// --------------------------------------------------------------------
// insert test below

      dut.i2c.start();
      dut.i2c.write_byte( 8'h00 );
      dut.i2c.write_byte( 8'hff );
      
      dut.i2c.start();
      dut.i2c.write_byte( 8'haa );
      dut.i2c.read_byte();
      
      dut.i2c.stop();
      
      
      repeat(100) @(posedge tb_clk); 
      
    end  
  endtask
      

endmodule

