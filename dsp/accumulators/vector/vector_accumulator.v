`default_nettype none


/*
*   Author: Sebastian Jorquera
*   Vector accumulator, meant to accumulate FFT channels (like an integrator)
*
*/


module vector_accumulator #(
    parameter DIN_WIDTH = 32,
    parameter VECTOR_LEN = 64,
    parameter DOUT_WIDTH = 64,
    parameter DATA_TYPE = "signed"  //signed or unsigned 
) (
    input wire clk,
    input wire new_acc,     //new accumulation, set it previous the first sample of the frame
    
    input wire [DIN_WIDTH-1:0] din,
    input wire din_valid,

    output wire [DOUT_WIDTH-1:0] dout,
    output wire dout_valid
);

reg [$clog2(VECTOR_LEN)-1:0] w_addr=0, r_addr=1;
reg [$clog2(VECTOR_LEN):0] acc_count=0;
reg [3*DIN_WIDTH-1:0] din_r=0;
reg [2:0] din_valid_r=0;
reg add_zero=0;
reg [1:0] add_zero_r=0;

always@(posedge clk)begin
    din_valid_r <= {din_valid_r[1:0], din_valid};
    din_r <= {din_r[2*DIN_WIDTH-1:0], din};
    add_zero_r <= {add_zero_r[0], add_zero};
    if(new_acc)
        add_zero <= 1'b1;
    else if(add_zero & (acc_count == (VECTOR_LEN-1)) & din_valid)
        add_zero <= 1'b0;
end


//pointers logic
always@(posedge clk)begin
    if(din_valid)begin
        r_addr <= r_addr+1;
        if(add_zero)begin
            if(acc_count == (VECTOR_LEN-1))
                acc_count <=0;
            else
                acc_count <= acc_count+1;
        end
        else
            acc_count <=0;
    end
    if(din_valid_r[2])
        w_addr<= w_addr+1;
end

wire [DOUT_WIDTH-1:0] bram_out;
wire [DOUT_WIDTH-1:0] bram_in;

sync_simple_dual_ram #(
    .RAM_WIDTH(DOUT_WIDTH),
    .RAM_DEPTH(VECTOR_LEN),
    .RAM_PERFORMANCE("HIGH_PERFORMANCE")
) ram_inst  (
    .clka(clk),
    .addra(w_addr),
    .dina(bram_in),
    .wea(din_valid_r[2]),   //check!!!
    .addrb(r_addr),
    .enb(1'b1),
    .rstb(1'b0), 
    .regceb(1'b1),
    .doutb(bram_out)         // RAM output data
);

reg [2*DOUT_WIDTH-1:0] bram_out_r=0;
always@(posedge clk)begin
    if(din_valid_r[0])
        bram_out_r <= {bram_out_r[DOUT_WIDTH-1:0], bram_out};
end


//wire [DOUT_WIDTH-1:0] actual_acc = bram_out_r[2*DOUT_WIDTH-1:DOUT_WIDTH];
//wire [DOUT_WIDTH-1:0] actual_acc = bram_out_r[DOUT_WIDTH-1:0];

wire [DOUT_WIDTH-1:0] actual_acc;
assign actual_acc = (din_valid_r[0] && din_valid_r[1]) ? 
    bram_out_r[DOUT_WIDTH-1:0] : bram_out_r[2*DOUT_WIDTH-1:DOUT_WIDTH];


reg dout_valid_r=0;

wire [DOUT_WIDTH-1:0] dout_data;
generate
    if(DATA_TYPE=="unsigned")begin
        wire [DIN_WIDTH-1:0] din_delay = din_r[DIN_WIDTH+:DIN_WIDTH];
        reg [DOUT_WIDTH-1:0] acc=0;
        reg [DOUT_WIDTH-1:0] dout_r=0;
        assign bram_in = acc;
        always@(posedge clk)begin
            if(din_valid_r[1])begin
                if(add_zero_r[1])begin
                    acc <= din_delay;
                    dout_valid_r <=1;
                    if(din_valid_r[2])begin
                        //continous valid data
                        dout_r <= bram_out_r[DOUT_WIDTH-1:0];
                    end
                    else begin
                        //not continous data
                        dout_r <= bram_out_r[2*DOUT_WIDTH:DOUT_WIDTH];
                    end
                end
                else begin
                    dout_valid_r <=0;
                    //acc <= actual_acc+din_delay;
                    if(din_valid_r[2]) begin
                        acc <= din_delay+bram_out_r[DOUT_WIDTH-1:0];
                    end
                    else begin
                        acc <= din_delay+bram_out_r[2*DOUT_WIDTH-1:DOUT_WIDTH];
                    end
                end
            end
            else 
                dout_valid_r <=0;
        end
        assign dout_data = dout_r;
    end
    else begin
        wire signed [DIN_WIDTH-1:0] din_delay = din_r[DIN_WIDTH+:DIN_WIDTH];
        reg signed [DOUT_WIDTH-1:0] acc=0;
        reg signed [DOUT_WIDTH-1:0] dout_r=0;
        assign bram_in = acc;
        always@(posedge clk)begin
            if(din_valid_r[1])begin
                if(add_zero_r[1])begin
                    acc <= $signed(din_delay);
                    dout_valid_r <=1;
                    if(din_valid_r[2])begin
                        //continous valid data
                        dout_r <= $signed(bram_out_r[DOUT_WIDTH-1:0]);
                    end
                    else begin
                        //not continous data
                        dout_r <= $signed(bram_out_r[2*DOUT_WIDTH:DOUT_WIDTH]);
                    end
                end
                else begin
                    dout_valid_r <=0;
                    //acc <= actual_acc+din_delay;
                    if(din_valid_r[2]) begin
                        acc <= $signed(din_delay)+$signed(bram_out_r[DOUT_WIDTH-1:0]);
                    end
                    else begin
                        acc <= $signed(din_delay)+$signed(bram_out_r[2*DOUT_WIDTH-1:DOUT_WIDTH]);
                    end
                end
            end
            else 
                dout_valid_r <=0;
        end
        assign dout_data = dout_r;
    end
endgenerate

assign dout = dout_data;
assign dout_valid = dout_valid_r;

endmodule
