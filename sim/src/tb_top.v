// --------------------------------------------------------------------
//
// --------------------------------------------------------------------

`timescale 1ns/10ps


module tb_top();

  parameter CLK_PERIOD = 42; // ~24MHZ (23.8MHZ) 

  reg tb_clk, tb_rst;

  initial 
    begin
      tb_clk <= 1'b1;      
      tb_rst <= 1'b1;
      
      #(CLK_PERIOD); #(CLK_PERIOD/3);
      tb_rst = 1'b0;
      
    end

  always
    #(CLK_PERIOD/2) tb_clk = ~tb_clk;
    
// --------------------------------------------------------------------
// tb_dut
  tb_dut dut( tb_clk, tb_rst );
  

  the_test test( tb_clk, tb_rst );
  
// --------------------------------------------------------------------
// run the test function

  initial
    begin
    
      // wait for system to come out of reset
      wait( ~tb_rst );
      
      repeat(2) @(posedge tb_clk);
      
      
      $display("\n^^^---------------------------------\n");
      
      test.run_the_test();
      
      $display("\n^^^---------------------------------\n");
      $display("^^^- Testbench done. %t.\n", $time);
      
      $stop();
    
    end
  
endmodule

