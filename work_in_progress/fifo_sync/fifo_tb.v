 module fifo_tb2;

    reg                           aclk;
    reg                           arstn;

    reg    [32-1:0]       in_data_tdata;
    reg                           in_data_tvalid;
    wire                          in_data_tready;

    wire   [32-1:0]       out_data_tdata;
    wire                          out_data_tvalid;
    reg                           out_data_tready;
    
    wire                          full;
    wire                          empty;


fifo_sync #(
    .DATA_WIDTH(32),
    .DEPTH(256)
) fifo_inst (
    .aclk(aclk),
    .arstn(arstn),
    .in_data_tdata(in_data_tdata),
    .in_data_tvalid(in_data_tvalid),
    .in_data_tready(in_data_tready),
    .out_data_tdata(out_data_tdata),
    .out_data_tvalid(out_data_tvalid),
    .out_data_tready(out_data_tready),
    .full(full),
    .empty(empty)
);

initial begin
    $from_myhdl(aclk, arstn, in_data_tdata, in_data_tvalid, out_data_tready);
    $to_myhdl(in_data_tready, out_data_tdata, out_data_tvalid, full, empty);
end

initial begin
    $dumpfile("fifo.vcd");
    $dumpvars();
end

endmodule
