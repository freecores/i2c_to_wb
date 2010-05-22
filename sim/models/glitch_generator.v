// --------------------------------------------------------------------
//
// --------------------------------------------------------------------


`timescale 1ns/10ps


module 
  glitch_generator
  #(
    parameter ENABLE = 0,
    parameter MAX_FREQ = 10000,
    parameter MAX_WIDTH = 120
  ) 
  (
    output out
  );
    
  
  // --------------------------------------------------------------------
  //  wires & regs
  reg glitch_generator_en;
  reg glitch;
  reg glitch_en;
  
    
  // --------------------------------------------------------------------
  //  init 
  initial
    begin
      glitch_generator_en <= ENABLE;
      glitch              <= 1'b0;
      glitch_en           <= 1'b0;
    
      forever
        begin: glitch_loop
        
          #({$random} % MAX_FREQ);
          
          if( ~glitch_generator_en )
            disable glitch_loop;
          
          glitch_en = 1'b1;
          #({$random} % MAX_WIDTH);
          
          glitch = ~glitch;
          #({$random} % MAX_WIDTH);
          
          glitch_en = 1'b0;
        
        end
    end      
    
      
  // --------------------------------------------------------------------
  //  enable_glitch_generator
  task enable_glitch_generator; 
    begin
    
    glitch_generator_en <= 1'b1;
         
    end    
  endtask
  
      
  // --------------------------------------------------------------------
  //  disable_glitch_generator
  task disable_glitch_generator; 
    begin
    
    glitch_generator_en <= 1'b0;
         
    end    
  endtask
  
      
  // --------------------------------------------------------------------
  //  outputs   

  assign (supply1, supply0) out = glitch_en ? glitch : 1'bz;
  
endmodule

