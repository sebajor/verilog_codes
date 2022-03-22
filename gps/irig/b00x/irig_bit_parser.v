`default_nettype none

/* Translate the widht of the pulse of the irig input to 0,1,2
where 2 represents a reference signal
*/

module irig_bit_parser (
    input wire clk,
    input wire din,
    
    input wire [31:0] debounce,
    input wire [31:0] zero_value,one_value,id_value,

    output debounce_din,
    output wire [1:0] translate_din,
    output wire valid
);

//debouncer, just wait some cycles before changing the value
reg [31:0] deb_counter=0;
reg hold=0, din_r=0;
reg din_signal =0;
always@(posedge clk)begin
    din_r <= din;
    if(~hold)begin
        if((~din_r & din) | (din_r & ~din))begin
            hold <= 1;
            din_signal <=  din_r;
        end
        else
            din_signal <= din;
    end 
    else begin
        if(deb_counter==debounce)begin
            hold <=0;
            din_signal <= din;
            deb_counter <=0;
        end
        else begin
            deb_counter <= deb_counter+1;
        end
    end
end

assign debounce_din = din_signal;
//

reg din_signal_r=0;
reg counting=0, count_valid=0;
reg [31:0] bit_count=0;
always@(posedge clk)begin
    din_signal_r <= din_signal;
    if(~din_signal_r & din_signal)begin
        count_valid <=0;
        counting <= 1;
        bit_count <=0;
    end
    else if(~din_signal & din_signal_r)begin
        counting <= 0;
        count_valid <= 1;
    end 
    else if(counting)begin
        bit_count <= bit_count+1;
        count_valid <=0;
    end
    else
        count_valid <=0;
end

//and finally decide which values is
reg valid_value=0;
reg [1:0] translate=0;

always@(posedge clk)begin
    if(count_valid)begin
        valid_value <= 1;
        if(bit_count < zero_value)
            translate <= 0;
        else if((zero_value <bit_count) &(bit_count < one_value))
            translate <= 1;
        else if((one_value < bit_count) &(bit_count < id_value))
            translate <= 2;
    end
    else
        valid_value <=0;
end

assign valid = valid_value;
assign translate_din = translate;

endmodule
