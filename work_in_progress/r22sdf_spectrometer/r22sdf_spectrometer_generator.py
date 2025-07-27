import numpy as np
import sys, os
import subprocess
import argparse
import shutil

###
fft_generator_code = '/home/seba/Workspace/verilog_codes/work_in_progress/fft/r22sdf/fft_generator/r22sdf_fft_generator.py'
###

parser = argparse.ArgumentParser()
parser.add_argument("-build_dir", "--build_dir", dest='build', default="./build")
parser.add_argument("-fft_size", "--fft_size", dest="fft_size", type=int)
parser.add_argument('-din_width', '--din_width', dest='din_width', type=int)
parser.add_argument('-din_point', '--din_point', dest='din_point', type=int)
parser.add_argument('-twiddle_width', '--twiddle_width', dest='twiddle_width', type=int, default=16)
parser.add_argument('-twiddle_point', '--twiddle_point', dest='twiddle_point', type=int, default=14)
parser.add_argument("-twiddle_dir", '--twiddle_dir', dest="twiddle_dir", default="./twiddles")
                    
parser.add_argument("-butterfly_delay", '--butterfly_delay', dest="butterfly_delay",type=int, default=0,
                    help="Delay between the BF1 and BF2 in each stage")
parser.add_argument("-stage_delay", '--stage_delay', dest="stage_delay", type=int, default=0,
                    help="Delay between stages")
parser.add_argument("--delay_feedback_type", "--delay_feedback_type", type=str, default="RAM",
                    help="The type of delay feedback on the FFT. The options are RAM and DELAY. By default we use RAM and DELAY in the last stage")

parser.add_argument('-dout_width', '--dout_width', dest='dout_width', type=int, default=64,
                    help="Output widht, shoudl be 32,64,128. This also is the accumulation width when integrating")
parser.add_argument('-ffts', '--ffts', dest='ffts', type=int, default=1,
                    help="Number of inputs and simoultaneous spectrometers to build")


    
def add_fft(fd,fft_size, din_width, fft_num=0):
    """
    fft num is just if you instantiate several ffts
    """
    fft_num = str(fft_num)
    stages = np.log2(fft_size)//2
    fd.write("wire signed [{:}:0] dout_re_fft{:}, dout_im_fft{:};\n".format(din_width+stages-1, fft_num, fft_num))
    fd.write("wire dout_fft{:}_valid;\n\n".format(fft_num))

    fd.write("r22sdf_fft{:} r22sdf_fft{:}_inst{:} (\n".format(fft_size, fft_size, fft_num))
    fd.write("\
    .clk(clk),\n\
    .rst(rst),\n\
    .din_valid(din_valid),\n\
    .din_re(din{:}_re),\n\
    .din_im(din{:}_im),\n\
    .dout_re(dout_re_fft{:}), \n\
    .dout_im(dout_im_fft{:}),\n\
    .dout_valid(dout_fft{:}_valid)\n\
    );\n\n".format(fft_num, fft_num, fft_num, fft_num, fft_num)
    )

def add_spectrometer_lane(fd, din_width, din_point, fft_size, dout_width, 
                          localparam=True, 
                          fft_num=0
                          ):
    fft_num = str(fft_num)
    if(localparam):
        fd.write("localparam FFT_WIDTH%s=%i;\n"%(fft_num, din_width))
        fd.write("localparam FFT_POINT%s=%i;\n\n"%(fft_num, din_point))
    fd.write("axil_spectrometer #(\n\
    .DIN_WIDTH({:}),\n\
    .DIN_POINT({:}),\n\
    .VECTOR_LEN({:}),\n\
    .POWER_DOUT(2*FFT_WIDTH{:}),\n\
    .POWER_DELAY(2),\n\
    .POWER_SHIFT(0),\n\
    .ACC_DIN_WIDTH(2*FFT_WIDTH{:}),\n\
    .ACC_DIN_POINT(2*FFT_POINT{:}),\n\
    .DOUT_CAST_SHIFT(0),\n\
    .DOUT_CAST_DELAY(2),\n\
    .DOUT_WIDTH({:}),\n\
    .DOUT_POINT(2*FFT_POINT{:}),\n\
    .BRAM_DELAY(2)\n\
    ) axil_spectrometer_inst{:} (\n".format(din_width,
             din_point,
             fft_size,
             fft_num,
             fft_num,
             fft_num,
             dout_width,
             fft_num,
             fft_num)
             )
    fd.write("\
    .clk(clk),\n\
    .din_re(dout_re_fft{:}),\n\
    .din_im(dout_im_fft{:}),\n\
    .din_valid(dout_fft{:}_valid),\n\
    .sync_in(sync_in),\n\
    .acc_len(acc_len),\n\
    .cnt_rst(cnt_rst),\n\
    .ovf_flag(),\n\
    .bram_ready(),\n\
    .axi_clock(axi_clock),\n\
    .axi_reset(axi_reset),\n\
    .s_axil_awaddr(s{:}_axil_awaddr),\n\
    .s_axil_awprot(s{:}_axil_awprot),\n\
    .s_axil_awvalid(s{:}_axil_awvalid),\n\
    .s_axil_awready(s{:}_axil_awready),\n\
    .s_axil_wdata(s{:}_axil_wdata),\n\
    .s_axil_wstrb(s{:}_axil_wstrb),\n\
    .s_axil_wvalid(s{:}_axil_wvalid),\n\
    .s_axil_wready(s{:}_axil_wready),\n\
    .s_axil_bresp(s{:}_axil_bresp),\n\
    .s_axil_bvalid(s{:}_axil_bvalid),\n\
    .s_axil_bready(s{:}_axil_bready),\n\
    .s_axil_araddr(s{:}_axil_araddr),\n\
    .s_axil_arvalid(s{:}_axil_arvalid),\n\
    .s_axil_arready(s{:}_axil_arready),\n\
    .s_axil_arprot(s{:}_axil_arprot),\n\
    .s_axil_rdata(s{:}_axil_rdata),\n\
    .s_axil_rresp(s{:}_axil_rresp),\n\
    .s_axil_rvalid(s{:}_axil_rvalid),\n\
    .s_axil_rready(s{:}_axil_rready)\n);\n\n".format(
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num,
        fft_num
        ))

    

def add_top(fd,fft_size, din_width, din_point, dout_size, ffts=1, tb=False):
    """
    Each fft wil have its own axi interface and inputs
    """
    axi_data_width = 32
    axi_addr_width  = int(np.log2(fft_size))+dout_size/axi_data_width-1 ##to account if the output is 64bits
    if(tb):
        fd.write("module r22sdf_spectrometer_{:}_tb (\n".format(fft_size))
    else:
        fd.write("module r22sdf_spectrometer_{:} (\n".format(fft_size))
    fd.write("//control signals\n\
    input wire clk,\n\
    input wire rst,\n\
    input wire din_valid,\n\
    input wire sync_in,\n\
    input wire [31:0] acc_len,\n\
    input wire cnt_rst,\n\n\
    input wire axi_clock,\n\
    input wire axi_reset,\n"
             )
    for i in range(ffts):
        fd.write("\
    input wire signed [{:}:0] din{:}_re, din{:}_im,\n".format(din_width-1, i,i))
        fd.write("\
    //axilite signals\n\
    input wire [{:}:0] s{:}_axil_awaddr,\n\
    input wire [2:0] s{:}_axil_awprot,\n\
    input wire s{:}_axil_awvalid,\n\
    output wire s{:}_axil_awready,\n\
    //write data channel\n\
    input wire [{:}:0] s{:}_axil_wdata,\n\
    input wire [{:}:0] s{:}_axil_wstrb,\n\
    input wire s{:}_axil_wvalid,\n\
    output wire s{:}_axil_wready,\n\
    //write response channel \n\
    output wire [1:0] s{:}_axil_bresp,\n\
    output wire s{:}_axil_bvalid,\n\
    input wire s{:}_axil_bready,\n\
    //read address channel\n\
    input wire [{:}:0] s{:}_axil_araddr,\n\
    input wire s{:}_axil_arvalid,\n\
    output wire s{:}_axil_arready,\n\
    input wire [2:0] s{:}_axil_arprot,\n\
    //read data channel\n\
    output wire [{:}:0] s{:}_axil_rdata,\n\
    output wire [1:0] s{:}_axil_rresp,\n\
    output wire s{:}_axil_rvalid,\n\
    input wire s{:}_axil_rready,\n".format(
            axi_addr_width+1,
            i,i,i,i,
            axi_data_width-1,i,
            axi_data_width//8-1,i,
            i,i,i,i,i,
            axi_addr_width+1,
            i,i,i,i,
            axi_data_width-1,
            i,i,i,i
            )
        )
    ##lets remove the final comma
    f_pos = fd.tell()
    fd.seek(f_pos-2,0)
    fd.write("\n);\n\n")

def instantiation(fd, fft_size, ffts):
    fd.write("r22sdf_spectrometer_{:} r22sdf_spectrometer_inst (\n\
    .clk(clk),\n\
    .rst(rst),\n\
    .din_valid(din_valid),\n\
    .acc_len(acc_len),\n\
    .axi_clock(axi_clock),\n\
    .axi_reset(axi_reset),\n\
    ".format(fft_size))
    for i in range(ffts):
        fd.write(".din{:}_re(din{:}_re),\n\
    .din{:}_im(din{:}_im),\n\
    .s{:}_axil_awaddr(s{:}_axil_awaddr),\n\
    .s{:}_axil_awprot(s{:}_axil_awprot),\n\
    .s{:}_axil_awvalid(s{:}_axil_awvalid),\n\
    .s{:}_axil_awready(s{:}_axil_awready),\n\
    .s{:}_axil_wdata(s{:}_axil_wdata),\n\
    .s{:}_axil_wstrb(s{:}_axil_wstrb),\n\
    .s{:}_axil_wvalid(s{:}_axil_wvalid),\n\
    .s{:}_axil_wready(s{:}_axil_wready),\n\
    .s{:}_axil_bresp(s{:}_axil_bresp),\n\
    .s{:}_axil_bvalid(s{:}_axil_bvalid),\n\
    .s{:}_axil_bready(s{:}_axil_bready),\n\
    .s{:}_axil_araddr(s{:}_axil_araddr),\n\
    .s{:}_axil_arvalid(s{:}_axil_arvalid),\n\
    .s{:}_axil_arready(s{:}_axil_arready),\n\
    .s{:}_axil_arprot(s{:}_axil_arprot),\n\
    .s{:}_axil_rdata(s{:}_axil_rdata),\n\
    .s{:}_axil_rresp(s{:}_axil_rresp),\n\
    .s{:}_axil_rvalid(s{:}_axil_rvalid),\n\
    .s{:}_axil_rready(s{:}_axil_rready),\n\
    " .format(
            i,i,i,i,i,i,i,i,i,i,
            i,i,i,i,i,i,i,i,i,i,
            i,i,i,i,i,i,i,i,i,i,
            i,i,i,i,i,i,i,i,i,i,i,i
            )
                 )
    ##Here I should delete the last comma
    pos = fd.tell()
    fd.seek(pos-6,0)
    fd.write("\n")
    fd.write(");\n\n")
    





if __name__ == '__main__':
    ##TODO!!!!
    args = parser.parse_args()
    os.makedirs(args.build, exist_ok=True)
    fft_size = args.fft_size

    stages = np.log2(fft_size)/2
    if(stages%1 !=0):
        print("The FFT size must be multiple of 2**2")
        sys.exit()
    stages = int(stages)
    ##here we should create the asked FFT with the r22sdf_fft_generator script..

    cmd = "python {:} -build_dir {:} -fft_size {:} -din_width {:} -din_point {:} -twiddle_width {:} -twiddle_point {:} -twiddle_dir {:} -butterfly_delay {:} -stage_delay {:}".format(
            fft_generator_code,
            os.path.abspath(args.build),
            args.fft_size,
            args.din_width,
            args.din_point,
            args.twiddle_width,
            args.twiddle_point,
            os.path.abspath(args.twiddle_dir),
            args.butterfly_delay,
            args.stage_delay
            )
    out = subprocess.Popen(cmd.split(' '), cwd=os.path.dirname(fft_generator_code))
    exit_code = out.wait()
    
    ##put the top module name
    filename = "r22sdf_fft"+str(fft_size)+"_spectrometer.v"
    fd = open(os.path.join(args.build, filename), 'w')
    fd.write("`default_nettype none\n\n\n")

    add_top(fd, fft_size, args.din_width, args.din_point, args.dout_width, ffts=args.ffts)
    
    for i in range(args.ffts):
        add_fft(fd, fft_size, args.din_width, fft_num=i)
        add_spectrometer_lane(fd, 
                              int(args.din_width+stages),
                              args.din_point, 
                              args.fft_size, 
                              args.dout_width, 
                              fft_num=i)
    fd.write("\n\n")
    fd.write("endmodule\n")
    fd.close()

    ##Create the testbench file
    filename = "r22sdf_fft"+str(fft_size)+"_spectrometer_tb.v"
    fd = open(os.path.join(args.build, filename), 'w')
    fd.write("`default_nettype none\n\n")
    fd.write('`include \"includes.v\"\n')
    fd.write('`include \"r22sdf_fft{:}.v\"\n'.format(fft_size))
    fd.write('`include \"r22sdf_fft{:}_spectrometer.v\"\n'.format(fft_size))


    add_top(fd, fft_size, args.din_width, args.din_point, args.dout_width, ffts=args.ffts, tb=True)
    
    fd.write("\n\n")
    fd.write("localparam FFT_SIZE = %i;\n"%fft_size)
    fd.write("localparam DIN_WIDTH = %i;\n"%args.din_width)
    fd.write("localparam DIN_POINT = %i;\n"%args.din_point)
    fd.write("localparam DOUT_WIDHT = %i;\n"%args.dout_width)
    fd.write("localparam FFTS= %i;\n\n"%args.ffts)
    instantiation(fd, args.fft_size, args.ffts)
    fd.write("endmodule")
    fd.close()
    #move the includes into the building
    shutil.copy('includes.v', os.path.join(args.build, "includes.v"))




    















