// --------------------------------------------------------------------
//
// --------------------------------------------------------------------


`include "timescale.v"


module
  glitch_filter
  #(
    parameter SIZE = 3
  ) 
  (
    input in,
    output reg out,
    
    output rise,
    output fall,
    
    input clk,
    input rst  
  );
  
  
  // --------------------------------------------------------------------
  //  in sync flop
  reg in_reg;
  always @(posedge clk)
    in_reg <= in;


  // --------------------------------------------------------------------
  //  glitch filter
  reg [(SIZE-1):0] buffer;
  always @(posedge clk)
    buffer <= { buffer[(SIZE-2):0], in_reg };
    
  wire all_hi = &{in_reg, buffer};
  wire all_lo = ~|{in_reg, buffer};
  
  wire out_en = (all_hi & in_reg) | (all_lo & ~in_reg);
  
  always @(posedge clk)
    if( out_en )
      out <= buffer[(SIZE-1)];


  // --------------------------------------------------------------------
  //  outputs  
  assign fall = all_lo & out;
  assign rise = all_hi & ~out;

  
endmodule

