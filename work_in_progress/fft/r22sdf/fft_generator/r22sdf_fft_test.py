import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import cocotb_test.simulator
import pytest
import itertools
import sys, os
cocotb_path = os.path.abspath('../../../../cocotb_python/')
sys.path.append(cocotb_path)
from two_comp import two_comp_pack, two_comp_unpack
sys.path.append(os.path.abspath('../'))
from python_test import BF_I, BF_II, bit_reversal_indices
import subprocess


def get_stage_twiddle_factors(stage_number):
    N = stage_number*2
    subset_index = stage_number//2
    twiddles = np.ones(N, dtype=complex)
    W_n = np.exp(-1j*2*np.pi/N)
    twiddles[subset_index:subset_index*2] = W_n**(np.arange(subset_index)*2)
    twiddles[subset_index*2:subset_index*3] = W_n**(np.arange(subset_index))
    twiddles[subset_index*3:] = W_n**(np.arange(subset_index)*3)
    return twiddles


@cocotb.test()
async def r22_sdf_fft_test(dut, thresh=1e-4):
    """
    """
    fft_size = int(dut.FFT_SIZE)
    din_width = int(dut.DIN_WIDTH)
    din_point = int(dut.DIN_POINT)
    iters = 10
    thresh = thresh*fft_size
    
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.rst.value =0
    dut.din_valid.value = 0
    dut.din_re.value = 0
    dut.din_im.value = 0
    await ClockCycles(dut.clk, 3)
    np.random.seed(123)



    din_re = np.random.random((iters, fft_size))-0.5
    #din_re = np.ones((iters, fft_size))*0.5
    din_im = np.random.random((iters, fft_size))-0.5
    #din_im = np.zeros((iters, fft_size))
    din =din_re+1j*din_im

    din_re_b = two_comp_pack(din_re.flatten(), din_width, din_point)
    din_im_b = two_comp_pack(din_im.flatten(), din_width, din_point)

    din_b = [din_re_b, din_im_b]
    
    gold_natural = np.fft.fft(din, axis=1)
    bit_ind = bit_reversal_indices(fft_size)
    gold = gold_natural[:, bit_ind].flatten()    ##CHECK HOW THE FLATTEN REORDERS IT

    cocotb.start_soon(write_data(dut, din_b))
    dout_width = int(din_width+np.log2(fft_size)/2)
    await read_data(dut, gold, dout_width, din_point, thresh)



async def write_data(dut, data):
    for re,im in zip(data[0], data[1]):
        dut.din_re.value = int(re)
        dut.din_im.value = int(im)
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold, dout_width, dout_point, thresh, 
                    comp='diff'):
    margins = [100-thresh, 100+thresh]  ##just if comp='perc'
    count = 0;
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout_re = int(dut.dout_re.value)
            dout_im = int(dut.dout_im.value)
            dout_re, dout_im = two_comp_unpack(np.array([dout_re, dout_im]), 
                                                dout_width,dout_point)
            print(count)
            print("real: gold: %.2f \t rtl:%.2f" %(gold[count].real, dout_re))
            print("imag: gold: %.2f \t rtl:%.2f" %(gold[count].imag, dout_im))
            print("")
            if(comp=='diff'):
                error_real = np.abs(gold[count].real-dout_re)
                error_imag = np.abs(gold[count].imag-dout_im)
                assert (error_real<thresh), "Error real part!"
                assert (error_imag<thresh), "Error imag part!"
            elif(comp=='perc'):
                error_real = 100*gold[count].real/dout_re
                error_imag = 100*gold[count].imag/dout_im
                assert ((margins[0]<error_real) and (error_real<margins[1])), "Error real part!"
                assert ((margins[0]<error_imag) and (error_imag<margins[1])), "Error imag part!"
            count +=1
        await ClockCycles(dut.clk,1)


@pytest.mark.parametrize("fft_size", [16, 64, 256, 1024, 4096])
#@pytest.mark.parametrize("fft_size", [16])
def test_r22_fft(request, fft_size):
    tests_dir = os.path.abspath(os.path.dirname(__file__))
    prev_dir = os.path.split(os.path.split(tests_dir)[0])[0]
    #first we need to create the files
    din_width = 16
    din_point = 14
    python_gen_path = os.path.join(tests_dir, "r22sdf_fft_generator.py")
    cmd = "python {:} --fft_size {:} --din_width {:} --din_point {:} --twiddle_dir {:}".format(
            python_gen_path,
            fft_size,
            din_width,
            din_point,
            os.path.join(tests_dir, "twiddles")
            )
    out = subprocess.Popen(cmd.split(' '))
    exit_code = out.wait()
    ###
    dut = 'r22sdf_fft'+str(fft_size)
    main = os.path.join(tests_dir, 'build', dut+'.v')
    tb = os.path.join(tests_dir, 'build', dut+'_tb.v')
    verilog_sources = [
            main,
            tb,
            "../fft_stage/r22sdf_fft_stage.v",
            "../../../../dsp/delay/delay.v",
            "../../../../xlx_templates/ram/simple_single_port/single_port_ram_read_first.v",
            "../../../../dsp/complex_mult/complex_mult.v",
            "../../../../dsp/dsp48_mult/dsp48_mult.v",
            "../../../../xlx_templates/rom_bin_init.v",
            "../../../../dsp/data_cast/signed_cast/signed_cast.v",
            "../feedback_line/feedback_delay_line.v",
            "../bf1/r22sdf_bf1.v",
            "../bf2/r22sdf_bf2.v",
            "../twidd_mult/r22sdf_twiddle_mult.v"
        ]
    
    cocotb_test.simulator.run(
        module = 'r22sdf_fft_test',
        verilog_sources = verilog_sources,
        toplevel = dut+'_tb',
        timescale="1ns/1ns",    ##sometimes the clock doesnt start
        force_compile=True,     ##as we change parameters in the hdl we need to compile each time
        seed=10,
            )














