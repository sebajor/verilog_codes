module seven_segment(
    input [7:0] data_in,
    input clk,
    output [6:0] disp1,
    output [6:0] disp2
);
    localparam zero_seg =   7'h7E;
    localparam one_seg  =   7'h30;
    localparam two_seg  =   7'h6D;
    localparam three_seg =  7'h79;
    localparam four_seg =   7'h33;
    localparam five_seg =   7'h5B;
    localparam six_seg  =   7'h5F;
    localparam seven_seg =  7'h70;
    localparam eigth_seg =  7'h7F;
    localparam nine_seg  =  7'h7B;
    localparam a_seg    =   7'h77;
    localparam b_seg    =   7'h1F;
    localparam c_seg    =   7'h4E;
    localparam d_seg    =   7'h3D;
    localparam e_seg    =   7'h4F;
    localparam f_seg    =   7'h47;
    
    
    
    reg [6:0] r_disp1, r_disp2;
    
    always@(posedge clk) begin
        case(data_in[3:0]) 
            4'h0    :   r_disp1 = zero_seg;
            4'h1    :   r_disp1 = one_seg;  
            4'h2    :   r_disp1 = two_seg;
            4'h3    :   r_disp1 = three_seg;
            4'h4    :   r_disp1 = four_seg;
            4'h5    :   r_disp1 = five_seg;
            4'h6    :   r_disp1 = six_seg;
            4'h7    :   r_disp1 = seven_seg;
            4'h8    :   r_disp1 = eigth_seg;
            4'h9    :   r_disp1 = nine_seg;
            4'ha    :   r_disp1 = a_seg;
            4'hb    :   r_disp1 = b_seg;
            4'hc    :   r_disp1 = c_seg;
            4'hd    :   r_disp1 = d_seg;
            4'he    :   r_disp1 = e_seg;
            4'hf    :   r_disp1 = f_seg;
            default :   r_disp1 = zero_seg;
        endcase
    end
    
    always@(posedge clk) begin
        case(data_in[7:4]) 
            4'h0    :   r_disp2 = zero_seg;
            4'h1    :   r_disp2 = one_seg;  
            4'h2    :   r_disp2 = two_seg;
            4'h3    :   r_disp2 = three_seg;
            4'h4    :   r_disp2 = four_seg;
            4'h5    :   r_disp2 = five_seg;
            4'h6    :   r_disp2 = six_seg;
            4'h7    :   r_disp2 = seven_seg;
            4'h8    :   r_disp2 = eigth_seg;
            4'h9    :   r_disp2 = nine_seg;
            4'ha    :   r_disp2 = a_seg;
            4'hb    :   r_disp2 = b_seg;
            4'hc    :   r_disp2 = c_seg;
            4'hd    :   r_disp2 = d_seg;
            4'he    :   r_disp2 = e_seg;
            4'hf    :   r_disp2 = f_seg;
            default :   r_disp2 = zero_seg;
        endcase
    end
    
    //this is only for the go board!
    assign disp1 = ~r_disp1;
    assign disp2 = ~r_disp2;

endmodule
