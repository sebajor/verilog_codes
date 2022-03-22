`default_nettype none

module irig_actual_time (
    input wire clk,
    input wire ce,
    input wire [5:0] sec, min,
    input wire [4:0] hr,
    input wire [8:0] day,
    input wire bcd_valid,
    input wire pps,
    
    output reg [5:0] sec_r, min_r,
    output reg [4:0] hr_r,
    output reg [8:0] day_r

);

reg bcd_valid_r=0;
always@(posedge clk)begin
    bcd_valid_r <= bcd_valid;
    if(bcd_valid & ~bcd_valid_r)begin
        sec_r <= sec;
        min_r <= min;
        hr_r <= hr;
        day_r <= day;
    end
    else if(bcd_valid & pps)begin
        if(sec_r == 59)begin
            sec_r <=0;
            if(min_r ==59)begin
                min_r <=0;
                if(hr_r==23)begin
                    hr_r<=0;
                    if(day_r==364)
                        day_r <=0;
                    else
                        day_r <= day_r+1;
                end
                else
                    hr_r <=hr_r+1;
            end
            else
                min_r <= min_r+1;

        end
        else
            sec_r <= sec_r+1;
    end
end


endmodule
