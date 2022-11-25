(* dont_touch = "yes" *)
module sfir_shifter #(
                      parameter dsize = 16,      // data bus width
                                nbtap = 4        // shift amount
                     )
                     (
                      input clk,                 // clock
                      input [dsize-1:0] datain,  // data input
                      output [dsize-1:0] dataout // data output
                     );

(* srl_style = "srl_register" *) reg [dsize-1:0] tmp [0:2*nbtap-1];
integer i;

always @(posedge clk)
 begin
  tmp[0] <= datain;
  for (i=0; i<=2*nbtap-2; i=i+1)
    tmp[i+1] <= tmp[i];
 end

assign dataout = tmp[2*nbtap-1];
endmodule

// sfir_even_symmetric_systolic_element - sub module which is used in top
module sfir_even_symmetric_systolic_element #(
                                              parameter dsize = 16
                                             )
                 (
                  input clk,
                  input signed [dsize-1:0] coeffin,
                  input signed [dsize-1:0] datain,
                  input signed [dsize-1:0] datazin,
                  input signed [2*dsize-1:0] cascin,
                  output signed [dsize-1:0] cascdata,
                  output reg signed [2*dsize-1:0] cascout
                  );

reg signed [dsize-1:0]   coeff;
reg signed [dsize-1:0]   data;
reg signed [dsize-1:0]   dataz;
reg signed [dsize-1:0]   datatwo;
reg signed [dsize:0]     preadd;
reg signed [2*dsize-1:0] product;

assign cascdata = datatwo;

always @(posedge clk)
 begin
   coeff   <= coeffin;
   data    <= datain;
   datatwo <= data;
   dataz   <= datazin;
   preadd  <= datatwo + dataz;
   product <= preadd  * coeff;
   cascout <= product + cascin;
 end

endmodule


module sfir_even_symmetric_systolic_top #(
                                          parameter nbtap = 4,
                                                    dsize = 16,
                                                    psize = 2*dsize
                                         )
                       (
                        input clk,
                        input signed [dsize-1:0] datain,
                        output signed [2*dsize-1:0] firout
                       );

wire signed [dsize-1:0] h [nbtap-1:0];
wire signed [dsize-1:0] arraydata [nbtap-1:0];
wire signed [psize-1:0] arrayprod [nbtap-1:0];

wire signed [dsize-1:0] shifterout;
reg  signed [dsize-1:0] dataz [nbtap-1:0];

assign h[0] =    7;
assign h[1] =   14;
assign h[2] = -138;
assign h[3] =  129;

assign firout = arrayprod[nbtap-1]; // Connect last product to output

sfir_shifter #(
                .dsize(dsize),
                .nbtap(nbtap)
               )
shifter_inst0 (
                .clk(clk),
                .datain(datain),
                .dataout(shifterout)
                );

generate
 genvar I;
   for (I=0; I<nbtap; I=I+1)
     if (I==0)
       sfir_even_symmetric_systolic_element #(
                                              .dsize(dsize)
                                             )
                                   fte_inst0 (
                                              .clk(clk),
                                              .coeffin(h[I]),
                                              .datain(datain),
                                              .datazin(shifterout),
                                              .cascin({32{1'b0}}),
                                              .cascdata(arraydata[I]),
                                              .cascout(arrayprod[I])
                                              );
     else
       sfir_even_symmetric_systolic_element #(
                                              .dsize(dsize)
                                             )
                                   fte_inst  (
                                              .clk(clk),
                                              .coeffin(h[I]),
                                              .datain(arraydata[I-1]),
                                              .datazin(shifterout),
                                              .cascin(arrayprod[I-1]),
                                              .cascdata(arraydata[I]),
                                              .cascout(arrayprod[I])
                                              );
endgenerate
endmodule // sfir_even_symmetric_systolic_top

// The following is an instantiation template for
// sfir_even_symmetric_systolic_top
/*
sfir_even_symmetric_systolic_top #(
                                   .nbtap(4),
                                   .dsize(16),
                                   .psize(2*dsize)
                                 )
   your_instance_name  (
                       .clk(clk),
                       .datain(datain),
                       .firout(firout)
                      );
*/
				

