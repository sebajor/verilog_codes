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
from python_test import BF_I, BF_II


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
async def r22sdf_twiddle_mult_test(dut, din_width=16, din_point=14, thresh=1e-3):
    ##read the parameters from the model..
    stage_number = int(dut.STAGE_NUMBER)
    iters = stage_number*10
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.rst.value =0
    dut.din_valid.value = 0
    dut.din_re.value = 0
    dut.din_im.value = 0
    await ClockCycles(dut.clk, 3)
    np.random.seed(123)

    din_re = np.random.random(iters)-0.5
    #din_re = np.ones(iters)*0.5
    din_im = np.random.random(iters)-0.5#
    #din_im = np.zeros(iters)
    din =din_re+1j*din_im

    din_re_b = two_comp_pack(din_re, din_width, din_point)
    din_im_b = two_comp_pack(din_im, din_width, din_point)

    din_b = [din_re_b, din_im_b]

    out_bf1 = []
    bf1 = BF_I(stage_number)
    for re,im in zip(din_re, din_im):
        bf1.process(re+1j*im)
        out_bf1.append(bf1.dout)
    out_bf1 = np.array(out_bf1[stage_number:])

    out_bf2 = []
    bf2 = BF_II(stage_number//2)
    for dat in out_bf1:
        bf2.process(dat)
        out_bf2.append(bf2.dout)
    out_bf2 = np.array(out_bf2[stage_number//2:])

    gold = []
    twiddles = get_stage_twiddle_factors(stage_number)
    #print(twiddles)
    for dat, twid in zip(out_bf2, itertools.cycle(twiddles)):
        gold.append(dat*twid)
    gold= np.array(gold)

    cocotb.start_soon(write_data(dut, din_b))
    await read_data(dut, gold, din_width+2, din_point, thresh)




async def write_data(dut, data):
    for re,im in zip(data[0], data[1]):
        dut.din_re.value = int(re)
        dut.din_im.value = int(im)
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)

async def read_data(dut, gold, dout_width, dout_point, thresh):
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
            assert (np.abs(gold[count].real-dout_re)<thresh), "Error real part!"
            assert (np.abs(gold[count].imag-dout_im)<thresh), "Error imag part!"
            count +=1
        await ClockCycles(dut.clk,1)


@pytest.mark.parametrize("fft_stage", [8, 32, 128, 512])
def test_fft_stage(request, fft_stage):
    tests_dir = os.path.abspath(os.path.dirname(__file__))
    prev_dir = os.path.split(os.path.split(tests_dir)[0])[0]
    dut = 'r22sdf_fft_stage'
    verilog_sources = [
            os.path.join(tests_dir, dut+'_tb.v'),
            os.path.join(tests_dir, dut+'.v'),
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
    dut = dut+'_tb'
    parameters = {}
    parameters['STAGE_NUMBER'] = fft_stage
    parameters['TWIDDLE_FILE'] = "\""+os.path.abspath(os.path.join(tests_dir, "twiddles/stage"+str(fft_stage)+"_16_14\""))

    cocotb_test.simulator.run(
        module = 'r22sdf_fft_stage_test',
        verilog_sources = verilog_sources,
        toplevel = dut,
        parameters = parameters,
        timescale="1ns/1ns",    ##sometimes the clock doesnt start
        force_compile=True,     ##as we change parameters in the hdl we need to compile each time
        seed=10,
            )


