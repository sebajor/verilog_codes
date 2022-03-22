`default_nettype none 
`include "includes.v"

module irig_bcd 
(
    input wire clk,
    input wire rst,

    input wire calibrate,
    input wire cont, //if you want to be trying to calibrate always put this in 1
    input wire [31:0] one_count, zero_count, id_count,
    input wire [31:0] debounce,

    input wire din,
    
    //bcd data
    output wire [5:0] sec,
    output wire [5:0] min,
    output wire [4:0] hr,
    output wire [8:0] day,
    output wire bcd_valid,

    //output pps each second
    output wire pps

);

localparam  IDLE = 4'd0,
            WAIT_SYNC = 4'd1,
            U_SEC = 4'd2,
            D_SEC = 4'd3,
            U_MIN = 4'd4,
            D_MIN = 4'd5,
            U_HR  = 4'd6,
            D_HR  = 4'd7,
            U_DAY = 4'd8,
            D_DAY = 4'd9,
            C_DAY = 4'd10,
            FINISH = 4'd11;


wire debounce_din, din_valid;
wire [1:0] translate_din;

irig_bit_parser irig_bit_parser(
    .clk(clk),
    .din(din),
    .debounce(debounce),
    .zero_value(zero_count),
    .one_value(one_count),
    .id_value(id_count),    //no es necesario..
    .debounce_din(debounce_din),
    .translate_din(translate_din),
    .valid(din_valid)
);


//here is the map of the values given by the irig format
//sync_ref: bit0
//u_sec: bit1-bit4
//d_sec: bit6-bit8
//u_min: bit10-bit13
//d_min: bit15-bit17
//u_hr:  bit20-bit23
//d_hr:  bit25-bit26
//u_day: bit30-bit33
//d_day: bit35-bit38
//c_day: bit40-bit41

reg [3:0] state=IDLE;
reg [31:0] counter=0;

reg [6:0] irig_count=0;  //irig count
reg one_flag=0;
reg finish=0;

reg [2:0] bit_count=0, bit_count_r=0;

reg [3:0] u_sec=0, u_min=0, u_hr=0, u_day=0, d_day=0;
reg [2:0] d_sec=0, d_min=0;
reg [1:0] d_hr=0, c_day=0;

always@(posedge clk)begin
    bit_count_r <= bit_count;
    if(rst)begin
        state <= IDLE;
    end
    else begin
        case(state)
        IDLE: begin
                finish <= 0;
                irig_count <= 0;
                one_flag <=0;
                if(calibrate)   state <= WAIT_SYNC;
                else            state <= IDLE;
            end
        WAIT_SYNC: begin
            //wait for two consecutives id bits
            if(din_valid)begin
                if(one_flag)begin
                    one_flag <=0;
                    if(translate_din ==2)begin
                        state <= U_SEC;
                        irig_count <= 1;
                        bit_count <=0;
                    end
                    else
                        state <= WAIT_SYNC;
                end
                else begin
                    if(translate_din==2)
                        one_flag <= 1;
                    else
                        one_flag <=0;
                end
            end
            else
                state <= WAIT_SYNC;
        end
        U_SEC:begin
            if(din_valid)begin
                irig_count <=  irig_count+1;
                if(bit_count<4)begin
                    bit_count <= bit_count+1;
                    u_sec[bit_count_r] <= translate_din;
                end
                else if(bit_count==4)begin
                    state <= D_SEC;
                    bit_count <= 0;
                end
            end
        end
        D_SEC:begin
            if(din_valid)begin
                irig_count <= irig_count+1;
                if(bit_count <3)begin
                    bit_count <= bit_count+1;
                    d_sec[bit_count_r] <= translate_din;
                end
                if(bit_count==3)begin
                    state <= U_MIN;
                    bit_count <=0;
                end
            end
        end
        U_MIN:begin
            if(din_valid)begin
                irig_count <= irig_count+1;
                if(bit_count < 4)begin
                    bit_count <= bit_count+1;
                    u_min[bit_count_r] <= translate_din;
                end
                else if(bit_count==4)begin
                    state <= D_MIN;
                    bit_count <= 0;
                end
            end
        end
        D_MIN:begin
            if(din_valid)begin
                irig_count <= irig_count+1;
                if(bit_count <4)begin
                    bit_count <= bit_count+1;
                    if(bit_count<3)
                        d_min[bit_count_r] <= translate_din;
                end
                else if(bit_count==4)begin
                    bit_count <= 0;
                    state <= U_HR;
                end
            end
        end
        U_HR:begin
            if(din_valid)begin
                irig_count <= irig_count +1;
                if(bit_count<4)begin
                    bit_count <= bit_count+1;
                    u_hr[bit_count_r] <= translate_din;
                end
                else if(bit_count==4)begin
                    bit_count <=0;
                    state <= D_HR;
                end
            end
        end
        D_HR:begin
            if(din_valid)begin
                irig_count <= irig_count+1;
                if(bit_count <4)begin
                    bit_count <= bit_count+1;
                    if(bit_count<2)
                        d_hr[bit_count_r] <= translate_din;
                end
                else if(bit_count==4)begin
                    bit_count <= 0;
                    state <= U_DAY;
                end
            end
        end
        U_DAY:begin
            if(din_valid)begin
                irig_count <= irig_count +1;
                if(bit_count<4)begin
                    bit_count <= bit_count+1;
                    u_day[bit_count_r] <= translate_din;
                end
                else if(bit_count==4)begin
                    bit_count <=0;
                    state <= D_DAY;
                end
            end
        end
        D_DAY:begin
            if(din_valid)begin
                irig_count <= irig_count +1;
                if(bit_count<4)begin
                    bit_count <= bit_count+1;
                    d_day[bit_count_r] <= translate_din;
                end
                else if(bit_count==4)begin
                    bit_count <=0;
                    state <= C_DAY;
                end
            end
        end
        C_DAY:begin
            if(din_valid)begin
                irig_count <= irig_count+1;
                if(bit_count <4)begin
                    bit_count <= bit_count+1;
                    if(bit_count<2)
                        c_day[bit_count_r] <= translate_din;
                end
                else if(bit_count==4)begin
                    bit_count <= 0;
                    state <= FINISH;
                end
            end
        end
        FINISH:begin
            finish <= 1;
            if(cont)
                state <= IDLE;
            else
                state <= FINISH;
        end
        default:    state = IDLE;
        endcase
    end
end

//transform the data to just one register

reg [5:0] sec_r=0;
reg [5:0] min_r=0;
reg [4:0] hr_r=0;
reg [8:0] day_r=0;
reg bcd_valid_r=0;

always@(posedge clk)begin
    if(finish)begin
        sec_r <= u_sec+10*d_sec;
        min_r <= u_min+10*d_min;
        hr_r <= u_hr+10*d_hr;
        day_r <= u_day+10*d_day+100*c_day;
        bcd_valid_r <=1;
    end
    else
        bcd_valid_r <=0;
end


assign sec = sec_r;
assign min = min_r;
assign hr = hr_r;
assign day = day_r;
assign bcd_valid = bcd_valid_r;

//search for pps
reg first_id=0, start_count=0;
reg pps_r=0;
//nop,this detects the pps after the 0.8ms of the second id
//we need to count the 100 pulses..
always@(posedge clk)begin
    if(rst)begin
        start_count <=0;
    end
    else if(din_valid)begin
        if(first_id)begin
            first_id <=0;
            if(translate_din==2)
                start_count <= 1;
        end
        else begin
            if(translate_din==2)
                first_id <= 1;
            else
                first_id <=0;
        end 
    end
end

reg [7:0] pps_counter=0;
reg debounce_din_r=0;
always@(posedge clk)begin
    debounce_din_r <= debounce_din;
    if(rst)begin
        pps_counter <=0;
        pps_r <=0;
    end
    else if(start_count)begin
        //count the rising edges
        if(~debounce_din_r & debounce_din)begin
            if(pps_counter==99)begin
                pps_r <=1;
                pps_counter <=0;
            end
            else begin
                pps_counter <= pps_counter+1;
                pps_r <=0;
            end
        end
        else
            pps_r <=0;
    end
    else
        pps_r <=0;
end
assign pps = pps_r;


endmodule
