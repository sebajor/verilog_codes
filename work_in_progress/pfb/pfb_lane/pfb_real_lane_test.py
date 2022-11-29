import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack


###
### Author:Sebastian Jorquera
###

@cocotb.test()
async def pfb_real_lane_test(dut, iters=1024, din_width=8, din_point=7, dout_width=18,
        dout_point=17, coeffs='pfb_coeffs/coeffs.npy', tresh=0.5):

    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dut.din.value = 0
    dut.sync_in.value =0 
    dut.din_valid.value = 0

    await ClockCycles(dut.clk, 10)
    np.random.seed(10)
    din = 0.75*np.sin(2*np.pi*np.arange(iters)/iters*10)#np.ones(iters)*0.5#-0.5    #the most simple test to compare the matlab output
    din_b = two_comp_pack(din, din_width, din_point)

    cocotb.fork(write_data(dut, din_b))
    await collect_output(dut, iters, dout_width,dout_point)
    
    


async def write_data(dut, din_b):
    dut.sync_in.value = 1   ##we use the sync as the valid signal (in this module doesnt do anything)
    await ClockCycles(dut.clk, 1)
    dut.sync_in.value = 0
    for dat in din_b:
        dut.din.value = int(dat)
        await ClockCycles(dut.clk,1)

async def collect_output(dut, iters, dout_width, dout_point):
    count =0;
    out = np.zeros(iters)
    ok = 0
    debug = []
    while(count<iters):
        valid = dut.sync_out.value
        dout = int(dut.dout.value)
        dout = two_comp_unpack(np.array(dout), dout_width, dout_point)
        debug.append(dout)
        if(valid|ok):
            ok = True
            dout = int(dut.dout.value)
            dout = two_comp_unpack(np.array(dout), dout_width, dout_point)
            out[count] = dout
            count +=1
        await ClockCycles(dut.clk,1)
    np.save('rtl_out.npy', out)
    np.save('debug.npy', debug)
    return 1
