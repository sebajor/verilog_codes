import numpy as np
import sys, os
cocotb_path = os.path.abspath('../../../../cocotb_python/')
sys.path.append(cocotb_path)
from two_comp import two_comp_pack, two_comp_unpack
sys.path.append(os.path.abspath('../twidd_mult'))
from twiddle_gen import write_bin_non_trivial_twiddle
import subprocess
import argparse
import shutil


parser = argparse.ArgumentParser()
parser.add_argument("-build_dir", "--build_dir", dest='build', default="build")
parser.add_argument("-fft_size", "--fft_size", dest="fft_size", type=int)
parser.add_argument('-din_width', '--din_width', dest='din_width', type=int)
parser.add_argument('-din_point', '--din_point', dest='din_point', type=int)
parser.add_argument('-twiddle_width', '--twiddle_width', dest='twiddle_width', type=int, default=16)
parser.add_argument('-twiddle_point', '--twiddle_point', dest='twiddle_point', type=int, default=14)
parser.add_argument("-twiddle_dir", '--twiddle_dir', dest="twiddle_dir", default="twiddles")
parser.add_argument("-butterfly_delay", '--butterfly_delay', dest="butterfly_delay",type=int, default=0,
                    help="Delay between the BF1 and BF2 in each stage")
parser.add_argument("-stage_delay", '--stage_delay', dest="stage_delay", type=int, default=0,
                    help="Delay between stages")
parser.add_argument("--delay_feedback_type", "--delay_feedback_type", type=str, default="RAM",
                    help="The type of delay feedback. The options are RAM and DELAY. By default we use RAM and DELAY in the last stage")

def generate_twiddle_factors(fft_size, twiddle_width, twiddle_point, twiddle_dir):
    n_stages = int(np.log2(fft_size)/2)
    os.makedirs(twiddle_dir, exist_ok=True)
    for i in range(1, n_stages):
        write_bin_non_trivial_twiddle(2**(2*i+1), twiddle_width, twiddle_point, twiddle_dir)
    return 1

def add_stage(fd, 
              stage_num,
              din_width,
              din_point, 
              twiddle_width,
              twiddle_point,
              twiddle_dir,
              butterfly_delay,
              delay_type):
    fd.write("wire signed [{:}:0] din_re_stage{:}, din_im_stage{:};\n".format(din_width-1, stage_num, stage_num))
    fd.write("wire din_valid_stage{:}, dout_valid_stage{:};\n".format(stage_num, stage_num))
    fd.write("wire signed [{:}:0] dout_re_stage{:}, dout_im_stage{:};\n\n\n".format(din_width+1, stage_num, stage_num))

    fd.write("r22sdf_fft_stage #(\n\
    .STAGE_NUMBER({:}),\n\
    .DIN_WIDTH({:}),\n\
    .DIN_POINT({:}),\n\
    .TWIDDLE_WIDTH({:}),\n\
    .TWIDDLE_POINT({:}),\n\
    .TWIDDLE_FILE(\"{:}\"),\n\
    .DELAY_BUTTERFLIES({:}),\n\
    .DELAY_TYPE(\"{:}\")\n\
) r22sdf_fft_stage_{:} (\n".format(
    stage_num,
    din_width,
    din_point,
    twiddle_width,
    twiddle_point,
    os.path.join(twiddle_dir, "stage{:}_{:}_{:}".format(stage_num, twiddle_width, twiddle_point)),
    butterfly_delay,
    delay_type,
    stage_num
    )
    )
    fd.write("\
    .clk(clk),\n\
    .din_re(din_re_stage{:}),\n\
    .din_im(din_im_stage{:}),\n\
    .din_valid(din_valid_stage{:}),\n\
    .rst(rst),\n\
    .dout_re(dout_re_stage{:}),\n\
    .dout_im(dout_im_stage{:}),\n\
    .dout_valid(dout_valid_stage{:})\n\
);\n\n".format(
    stage_num,
    stage_num,
    stage_num,
    stage_num, 
    stage_num,
    stage_num
    ))


def assign_din(fd, prev_stage, curr_stage):
    if(prev_stage is None):
        ##we are at the beginign
        fd.write("assign din_re_stage{:} = din_re;\n".format(curr_stage))
        fd.write("assign din_im_stage{:} = din_im;\n".format(curr_stage))
        fd.write("assign din_valid_stage{:} = din_valid;\n\n".format(curr_stage))
    else:
        #assign to the delayed signal of the previous stage
        fd.write("assign din_re_stage{:} = dout_re_stage{:}_r;\n".format(curr_stage, prev_stage))
        fd.write("assign din_im_stage{:} = dout_re_stage{:}_r;\n".format(curr_stage, prev_stage))
        fd.write("assign din_valid_stage{:} = dout_valid_stage{:}_r;\n\n".format(curr_stage, prev_stage))


def add_delay(fd, stage_num, din_width, stage_delay):
    fd.write("wire signed [{:}:0] dout_re_stage{:}_r, dout_im_stage{:}_r;\n".format(din_width-1, stage_num, stage_num))
    fd.write("wire dout_valid_stage{:}_r;\n\n".format(stage_num))
    fd.write("delay #(\n\
    .DATA_WIDTH({:}),\n\
    .DELAY_VALUE({:})\n\
) delay_stage{:} (\n\
    .clk(clk),\n\
    .din({{dout_re_stage{:}, dout_im_stage{:}, dout_valid_stage{:} }}),\n\
    .dout({{dout_re_stage{:}_r, dout_im_stage{:}_r, dout_valid_stage{:}_r }})\n\
);\n\n".format(
                2*din_width+1,
                stage_delay,
                stage_num,
                stage_num,
                stage_num,
                stage_num,
                stage_num,
                stage_num,
                stage_num
                )
             )
    

def add_top(fd,fft_size, din_width, stages, tb=False):
    if(tb):
        fd.write("module r22sdf_fft{:}_tb (\n".format(fft_size))
    else:
        fd.write("module r22sdf_fft{:} (\n".format(fft_size))
    fd.write("\
    input wire clk,\n\
    input wire rst,\n\
    input wire din_valid,\n\
    input wire signed [{:}:0] din_re, din_im,\n\n\
    output wire signed [{:}:0] dout_re, dout_im,\n\
    output wire dout_valid\n\
    );\n\n".format(din_width-1, din_width+stages-1)
    )


def instantiation(fd, fft_size):
    fd.write("r22sdf_fft"+str(fft_size)+" r22sdf_fft"+str(fft_size)+"_inst (\n")
    fd.write("\
    .clk(clk),\n\
    .rst(rst),\n\
    .din_valid(din_valid),\n\
    .din_re(din_re),\n\
    .din_im(din_im),\n\
    .dout_re(dout_re),\n\
    .dout_im(dout_im),\n\
    .dout_valid(dout_valid)\n\
    );\n\n")




if __name__ == '__main__':
    args = parser.parse_args()
    os.makedirs(args.build, exist_ok=True)
    fft_size = args.fft_size
    stages = np.log2(fft_size)/2
    if(stages%1 !=0):
        print("The FFT size must be multiple of 2**2")
        sys.exit()
    filename = "r22sdf_fft"+str(fft_size)+".v"
    fd = open(os.path.join(args.build, filename), 'w')
    stages = int(stages)
    ##put the top module name
    

    fd.write("`default_nettype none\n\n\n")
    add_top(fd, fft_size, args.din_width, stages)
    prev_stage = None
    for i in range(stages):
        stage_num = int(fft_size/2/(4**i))
        din_width_stage = args.din_width+2*i
        if(stage_num!=2):
            delay_type = "RAM"
            generate_twiddle_factors(2*stage_num, args.twiddle_width, args.twiddle_point, args.twiddle_dir)
        else:
            delay_type = "DELAY"
        add_stage(fd, 
              stage_num,
              din_width_stage,
              args.din_point, 
              args.twiddle_width,
              args.twiddle_point,
              args.twiddle_dir,
              args.butterfly_delay,
              delay_type)
        assign_din(fd, prev_stage, stage_num)
        add_delay(fd, stage_num, din_width_stage+2, args.stage_delay)
        prev_stage = stage_num
        
    ##now we assign the last output to the output port
    fd.write("assign dout_re = dout_re_stage{:}_r;\n".format(prev_stage))
    fd.write("assign dout_im = dout_im_stage{:}_r;\n".format(prev_stage))
    fd.write("assign dout_valid = dout_valid_stage{:}_r;\n\n".format(prev_stage))
    fd.write("endmodule")
    fd.close()

    #testbench
    filename = "r22sdf_fft"+str(fft_size)+"_tb.v"
    fd = open(os.path.join(args.build, filename), 'w')
    fd.write("`default_nettype none\n\n")
    fd.write("`include \"includes.v\"\n")
    fd.write("`include \"r22sdf_%i.v\"\n\n\n"%fft_size)
    add_top(fd, fft_size, args.din_width, stages, tb=True)
    fd.write("\n\n")
    fd.write("localparam FFT_SIZE = %i;\n"%fft_size)
    fd.write("localparam DIN_WIDTH = %i;\n"%args.din_width)
    fd.write("localparam DIN_POINT = %i;\n"%args.din_point)
    ##instantiation
    instantiation(fd, fft_size)
    fd.write("endmodule")
    fd.close()
    shutil.copy('includes.v', os.path.join(args.build, "includes.v"))
    




