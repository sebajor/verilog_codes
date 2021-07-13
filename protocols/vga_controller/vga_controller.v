module vga_controller #(
	parameter H_MAX = 800,
    parameter H_ACTIVE = 640,
    parameter H_FRONT = 18,
    parameter H_SYNC = 92,
    parameter H_BACK = 50,
    parameter V_MAX = 525,
    parameter V_ACTIVE = 480,
    parameter V_FRONT = 10,
    parameter V_SYNC = 2,
    parameter V_BACK = 33
)(
	input i_Clk,
    input rst_n,
    
    output h_sync,
    output v_sync,
    output [2:0] red_val,
    output [2:0] blue_val,
    output [2:0] green_val,

	output [$clog2(H_ACTIVE)-1:0] x_pos,
	output [$clog2(V_ACTIVE)-1:0] y_pos,
	output 	valid_pos,
	input 	[2:0] r_pxl_value,
	input 	[2:0] g_pxl_value,
	input 	[2:0] b_pxl_value
);

	reg [$clog2(H_MAX)-1:0] h_counter = 0;
    reg [$clog2(V_MAX)-1:0] v_counter = 0;

	reg rst_sys, r1_rst;
    
    always@(posedge i_Clk)begin
        if(~rst_n)
            {rst_sys, r1_rst} = {r1_rst, 1'b0};
        else
            {rst_sys, r1_rst} = {r1_rst, 1'b1};
    end


	always@(posedge i_Clk)begin
		if(~rst_sys)begin
			h_counter <= 0;
			v_counter <= 0;
		end
		else begin
			if(h_counter == (H_MAX-1))begin
				h_counter <=0;
				if(v_counter == (V_MAX-1))
					v_counter <= 0;
				else
					v_counter <= v_counter +1;
			end
			else begin
				h_counter <= h_counter +1;
			end
		end	
	end

	
	wire h_sync1, h_sync2;
	assign h_sync1 = (h_counter < (H_ACTIVE+H_FRONT-1));
    assign h_sync2 = (h_counter > (H_ACTIVE+H_FRONT+H_SYNC-2));//check!
	
	wire v_sync1, v_sync2;
	assign v_sync1 = (v_counter < (V_ACTIVE+V_FRONT-1));
    assign v_sync2 = (v_counter > (V_ACTIVE+V_FRONT+V_SYNC-2));//check!
	
	wire active;
	assign active = (h_counter <(H_ACTIVE-1))&&(v_counter<(V_ACTIVE-1));
	
	
	assign x_pos = h_counter[$clog2(H_ACTIVE)-1:0];
	assign y_pos = v_counter[$clog2(V_ACTIVE)-1:0];
	assign valid_pos = active;
	
	
	assign red_val = (active) ? r_pxl_value : 3'b0;
	assign green_val = (active) ? g_pxl_value:3'b0;
	assign blue_val = (active) ? b_pxl_value :3'b0;

	assign h_sync = (h_sync1 | h_sync2);
    assign v_sync = (v_sync1 | v_sync2);

endmodule 
