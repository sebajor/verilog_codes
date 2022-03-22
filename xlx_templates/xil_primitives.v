
module ODDR(
    output wire Q,
    input wire D1, D2,
    input wire C,
    input wire CE, R,S
);

endmodule


module IBUFGDS (
    input wire I, IB,
    output wire O
);

endmodule

module IBUFDS #(
    parameter DIFF_TERM = "FALSE",
    parameter IBUF_LOW_PWR = "FALSE",
    parameter IOSTANDARD = "DEFAULT"
) (
    input wire I, IB,
    output wire O
);

endmodule

module BUFG (
    input wire I,
    output wire O
);

endmodule


module OBUFDS #(
    parameter IOSTANDARD = "DEFAULT",
    parameter SLEW = "SLOW"
) (
    input wire I,
    output wire O,OB
);

endmodule
