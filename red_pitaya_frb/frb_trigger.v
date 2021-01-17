`default_nettype none

module frb_trigger #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 512,
    parameter INIT_VALS = "trig.mem"
) (
    //axi signals, only write channel 
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETn,
    //address write channel
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [2:0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    //write data channel
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    //write response channel
    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,    
    
    //read data
    
    
    //custom.
    input wire [31:0] pulse_width,
    input wire en_frb,
    input wire rst_frb,     
    //dac out
    output wire [16:0] dac_out
);

reg axi_awready=1;
reg axi_wready=1;
reg axi_bvalid=0;

localparam integer ADDR_LSB=2;
localparam integer AW = C_S_AXI_ADDR_WIDTH-2; //it byte addressing
localparam integer DW = C_S_AXI_DATA_WIDTH;

reg [DW-1:0] slv_mem [C_S_AXI_ADDR_WIDTH-1:0]; //why put them backwards?

initial begin
    $readmemh(INIT_VALS, slv_mem);
end



reg [C_S_AXI_ADDR_WIDTH-1:0] pre_waddr=0, waddr=0;
reg [C_S_AXI_DATA_WIDTH-1:0] pre_wdata=0, wdata=0;
reg [C_S_AXI_DATA_WIDTH/8-1:0] pre_wstrb=0, wstrb=0;

wire valid_write_addr, valid_write_data, write_resp_stall;

assign valid_write_addr = S_AXI_AWVALID || !axi_awready;
assign valid_write_data = S_AXI_WVALID || !axi_wready;
assign write_resp_stall = S_AXI_BVALID && !S_AXI_BREADY;


//write ready signal
always@(posedge S_AXI_ACLK)begin
    if(!S_AXI_ARESETn)
        axi_awready<= 1;
    else if(write_resp_stall)begin
        //if the buffer is full we have to lower it
        axi_awready <= !valid_write_addr;
    end
    else if(valid_write_data) begin
        //write data is available and we have space in the buffer
        axi_awready <= 1;
    end
    else
        axi_awready <= axi_awready && !S_AXI_AWVALID;
end

//write data ready signal
always@(posedge S_AXI_ACLK)begin
    if(!S_AXI_ARESETn)
        axi_wready <= 1;
    else if(write_resp_stall) begin
        //there is something in the buffer, we need to wait
        axi_wready <= !valid_write_data;
    end
    else if(valid_write_addr)begin
        //the buffer is empty
        axi_wready <= 1;
    end
    else begin
        //default case
        axi_wready <= axi_wready && !S_AXI_WVALID; //? i dont get it
    end
end

//buffering the addr
always@(posedge S_AXI_ACLK)begin
    if(S_AXI_AWREADY)
        pre_waddr <= S_AXI_AWADDR;
end
//buffering the data
always@(posedge S_AXI_ACLK)begin
    if(S_AXI_WREADY)begin
        pre_wdata <= S_AXI_WDATA;
        pre_wstrb <= S_AXI_WSTRB;
    end
end

always@(*)begin
    if(!axi_awready)
        waddr = pre_waddr;
    else
        waddr = S_AXI_AWADDR;

end


always@(*)begin
    if(!axi_wready) begin
        //read write data from the buffer
        wstrb = pre_wstrb;
        wdata = pre_wdata;
    end
    else begin
        wstrb = S_AXI_WSTRB;
        wdata = S_AXI_WDATA;
    end
end


//write the data
always@(posedge S_AXI_ACLK)begin
    if(!write_resp_stall && valid_write_addr &&valid_write_data) begin
        if(wstrb[0])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][7:0]<= wdata[7:0];
        if(wstrb[1])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][15:8]<=wdata[15:8];
        if(wstrb[2])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][23:16]<=wdata[23:16];
        if(wstrb[3])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][31:24]<=wdata[31:24];
    end
end

//write response valid signal
always@(posedge S_AXI_ACLK)begin
    if(!S_AXI_ARESETn)
        axi_bvalid <= 0;
    else if (valid_write_addr && valid_write_data)begin
        //here everything works
        axi_bvalid <= 1;
    end
    else if(S_AXI_BREADY)
        axi_bvalid <= 0;
end

//when en_frb start to put the 







//read the data
reg [C_S_AXI_ADDR_WIDTH-1:0] frb_addr=0;
reg [31:0] frb_counter=0;
reg frb_finish=0;

reg [31:0] frb_period=0;
always@(posedge S_AXI_ACLK)begin
    frb_period <= slv_mem[frb_addr];
end

always@(posedge S_AXI_ACLK)begin
    if(rst_frb)begin
        frb_addr <=0;
        frb_counter<=0;
        frb_finish<=0;
    end
    else if(en_frb&& !frb_finish) begin
        if(&frb_addr)
            frb_finish <=1;
        else if(frb_counter==frb_period)begin
            frb_counter <= 0;
            frb_addr <= frb_addr+1;
        end
        else begin
            frb_counter <= frb_counter +1;
            frb_addr <= frb_addr;
        end
    end
    else begin
        frb_counter <= frb_counter;
        frb_addr <= frb_addr;
    end 
end

//extend the pulse for certain number of cycles
reg [31:0] pulse_counter=0;
reg pulse_flag=0;
always@(posedge S_AXI_ACLK)begin
    if(en_frb && !frb_finish && (frb_counter==frb_period))begin
        pulse_flag <=1;
    end
    else if(pulse_flag)begin
        if(pulse_counter==pulse_width)begin
            pulse_flag <=0;
            pulse_counter <=0;
        end
        else begin
            pulse_counter <= pulse_counter +1;
            pulse_flag <=1;
        end
    end
    else begin
        pulse_counter <=0;
        pulse_flag <=0;
    end
end

//dac output 
//no recuerdo los niveles de voltaje de esta custion!! revisar
reg [15:0] dac_val=0;

always@(posedge S_AXI_ACLK)begin
    if(pulse_flag)
        dac_val <= 16'h5FFF;    //creo que es 1V.. pero 0x6000 ya es -1!! cuidado
    else
        dac_val <=0;
end

assign dac_out = dac_val;


endmodule
