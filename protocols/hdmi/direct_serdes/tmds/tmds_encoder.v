`default_nettype none

module tmds_encoder #(
    parameter CHANNEL =0    //HDMI 1.4a allows 3 types
) (
    input wire pxl_clk,
    input wire [7:0] video_data,
    input wire [3:0] data_island,
    input wire [1:0] control_data,
    input wire [2:0] mode, //0:control,1:video,2:video guard,3:island,4:island guard
    output wire [9:0] tmds
);
//Section 5.4.4.1

reg [8:0] q_m=0;    //9 bit intermediate value
reg [9:0] q_out=10'b1101010100;

wire [9:0] video_coding;
assign video_coding = q_out;

reg [3:0] N1=0;
reg signed [4:0] N1_q=0, N0_q=0;

always@(*)begin
    N1 = video_data[0]+video_data[1]+video_data[2]+video_data[3]+
        video_data[4]+video_data[5]+video_data[6]+video_data[7];
    N1_q = q_m[0]+q_m[1]+q_m[2]+q_m[3]+q_m[4]+q_m[5]+q_m[6]+q_m[7];
    N0_q = 8-N1_q;
end

reg signed [4:0] acc_add=0;
reg signed [4:0] acc=0;

integer i;
reg [1:0] debug=0;
always@(*)begin
    //intermediate encoding
    q_m[0] = video_data[0];
    if(N1 > 4'd4 || (N1==4 & video_data[0]==0))begin
        for(i=0; i<7; i=i+1)begin
            q_m[1+i] = q_m[i] ~^ video_data[i+1];
        end
        q_m[8] = 1'b0;
    end
    else begin
        for(i=0; i<7; i=i+1)begin
            q_m[1+i] = q_m[i] ^ video_data[i+1];
        end
        q_m[8] = 1'b1;
    end
    //second encoding (could be synchronous, and pipeline the other fields too?)
    if(acc==0 |  (N1_q == N0_q))begin
        if(q_m[8])begin
            debug <=0;
            q_out = {~q_m[8], q_m};
            acc_add = N1_q-N0_q;
        end
        else begin
            debug <= 1;
            q_out = {~q_m[8], q_m[8], ~q_m[7:0]};
            acc_add = N0_q-N1_q;
        end
    end
    else begin
        if(acc>0 & (N1_q>N0_q) | (acc<0 & (N1_q <N0_q)))begin
            debug <=2;
            q_out = {1'b1, q_m[8], ~q_m[7:0]};
            acc_add = $signed(N0_q-N1_q)+({3'b0,q_m[8],1'b0});  //thats qm[8]<<1
        end 
        else begin 
            debug <= 3;
            q_out = {1'b0, q_m[8:0]};
            acc_add = $signed(N1_q-N0_q)-$signed({3'd0,~q_m[8],1'b0});
        end
    end
end


always@(posedge pxl_clk)begin
    if(mode==1)
        acc <= $signed(acc)+$signed(acc_add);
    else
        acc <= 0;
end


//section 5.4.2
reg [9:0] control_coding=0;
always@(*)begin
    case(control_data)
        2'b00: control_coding = 10'b1101010100;
        2'b01: control_coding = 10'b0010101011;
        2'b10: control_coding = 10'b0101010100;
        2'b11: control_coding = 10'b1010101011;
        default: control_coding = 10'b1101010100; 
    endcase
end

//section 5.4.3, could be replaced by an lfsr...    
reg [9:0] terc4_coding=0;
always@(*)begin
    case(data_island)
        4'b0000 : terc4_coding = 10'b1010011100;
        4'b0001 : terc4_coding = 10'b1001100011;
        4'b0010 : terc4_coding = 10'b1011100100;
        4'b0011 : terc4_coding = 10'b1011100010;
        4'b0100 : terc4_coding = 10'b0101110001;
        4'b0101 : terc4_coding = 10'b0100011110;
        4'b0110 : terc4_coding = 10'b0110001110;
        4'b0111 : terc4_coding = 10'b0100111100;
        4'b1000 : terc4_coding = 10'b1011001100;
        4'b1001 : terc4_coding = 10'b0100111001;
        4'b1010 : terc4_coding = 10'b0110011100;
        4'b1011 : terc4_coding = 10'b1011000110;
        4'b1100 : terc4_coding = 10'b1010001110;
        4'b1101 : terc4_coding = 10'b1001110001;
        4'b1110 : terc4_coding = 10'b0101100011;
        4'b1111 : terc4_coding = 10'b1011000011;
        default : terc4_coding = 10'b1010011100;
    endcase
end

//section 5.2.2.1
wire [9:0] video_guard=0;
generate 
    if(CHANNEL==0 | CHANNEL==2)
        assign video_guard = 10'b1011001100;
    else
        assign video_guard = 10'b0100110011; 
endgenerate

//section 5.2.3.3
wire [9:0] data_guard=0;
generate 
    if(CHANNEL==1 | CHANNEL==2)
        assign data_guard = 10'b0100110011;
    else begin
        assign data_guard = control_data == 2'b00 ? 10'b1010001110
            : control_data == 2'b01 ? 10'b1001110001
            : control_data == 2'b10 ? 10'b0101100011
            : 10'b1011000011;
    end
endgenerate

//select mode
reg [9:0] tmds_r =0;
assign tmds = tmds_r;
always@(posedge pxl_clk)begin
    case(mode)
        3'd0: tmds_r <= control_coding;
        3'd1: tmds_r <= video_coding;
        3'd2: tmds_r <= video_guard;
        3'd3: tmds_r <= terc4_coding;
        3'd4: tmds_r <= data_guard;
    endcase
end

endmodule
