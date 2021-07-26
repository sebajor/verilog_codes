`default_nettype none
`include "includes.v"

/*
    typical solution of the quadratic equation
    x1 = (-b +sqrt(b**2-4ac))/2
    x2 = (-b- sqrt(b**2-4ac))/2
*/

module quad_root #(
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 14,
    parameter SQRT_IN_WIDTH = 10,
    parameter SQRT_IN_PT = 7,
    
) (
