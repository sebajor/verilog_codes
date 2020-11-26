//normal fifo working in only one clock domain
module fifo_sync #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 256
) (
    input   wire                        aclk,
    input   wire                        arstn,

    input   wire [DATA_WIDTH-1:0]       in_data_tdata,
    input   wire                        in_data_tvalid,
    output  wire                        in_data_tready,

    output  wire [DATA_WIDTH-1:0]       out_data_tdata,
    output  wire                        out_data_tvalid,
    input   wire                        out_data_tready,
    
    output  wire                        full,
    output  wire                        empty
);

reg [$clog2(DEPTH):0] w_ptr;
reg [$clog2(DEPTH):0] r_ptr;


reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];

reg full_r, empty_r;
reg r_valid;
reg w_ready;

reg [DATA_WIDTH-1:0] dout;


//initialize the memory... for simulation only
integer i;
initial begin
    for(i=0;i<DEPTH-1;i++)begin
        mem[i] = 0;
    end
end


//synchronizer for the reset
reg rst_fifo; 
reg rst_system;
always@(posedge aclk)begin
    if(~arstn)
        {rst_system, rst_fifo} <= {rst_fifo, 1'b0};
    else
        {rst_system, rst_fifo} <= 2'b11;
end


//write side
always@(posedge aclk)begin
    if(~rst_system)begin
        w_ptr <= 0;
        w_ready <= 0;
    end
    else
        if(~full)begin
            w_ready <= 1;
            if(in_data_tvalid)
                w_ptr <= w_ptr+1;
            else
                w_ptr <= w_ptr;
        end
        else begin
            w_ready <=0;
            w_ptr <= w_ptr;
        end
end

always@(posedge aclk)begin
    if(in_data_tvalid && (~full_r))
        mem[w_ptr[$clog2(DEPTH)-1:0]] <= in_data_tdata;
end

//read side

always@(posedge aclk) begin
    if(~rst_system) begin
        r_ptr <= 0;
        r_valid <= 0;
    end
    else begin
        if((~empty) && (out_data_tready)) begin
            r_ptr <= r_ptr+1;
            r_valid <= 1;
        end
        else begin
            r_valid <= 0;
            r_ptr <= r_ptr;
        end
    end
end

//check timming!
always@(posedge aclk) begin
    dout <= mem[r_ptr[$clog2(DEPTH)-1:0]];
end

//empty and full logic

always@(posedge aclk)begin
    if(~rst_system)begin
        empty_r <= 1;
        full_r <= 0;
    end 
    else begin
        empty_r <= (w_ptr == r_ptr);
        full_r <= ((w_ptr[$clog2(DEPTH)]==~r_ptr[$clog2(DEPTH)]) && 
                (w_ptr[$clog2(DEPTH)-1:0]==r_ptr[$clog2(DEPTH)-1:0]));

    end
end

assign in_data_tready = w_ready && rst_system;
assign out_data_tvalid = r_valid && rst_system;

//assign empty = empty_r;
assign full = full_r;
assign empty = (w_ptr==r_ptr);

assign out_data_tdata = dout;   //check!!



endmodule





