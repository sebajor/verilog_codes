import numpy as np
import cocotb, sys
sys.path.append('../../../')
from two_comp import two_comp_pack, two_comp_unpack
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock

###
### Author: Sebastian Jorquera
###

@cocotb.test()
async def quad_root_iterative_test(dut, iters=1024, din_width=16, din_pt=14,
        dout_width = 16, dout_pt=13, thresh=0.1, cont=0, burst=10):

    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.b.value = 0
    dut.c.value = 0
    dut.din_valid.value =0
    dut.band_in.value = 0
    await ClockCycles(dut.clk, 4)


    np.random.seed(19)
    b = np.random.random(iters)-0.5
    c = np.random.random(iters)-0.5

    b_bin = two_comp_pack(b, din_width, din_pt)
    c_bin = two_comp_pack(c, din_width, din_pt)

    cocotb.fork(write_data(dut, b_bin,c_bin,cont, burst))
    await read_data(dut,b,c,dout_width, dout_pt, thresh)


async def write_data(dut, b,c, cont, burst_len):
    dut.band_in.value = 1
    if(cont):
        for i in range(len(b)):
            dut.b.value = int(b[i])
            dut.c.value = int(c[i])
            dut.din_valid.value = 1;
            await ClockCycles(dut.clk, 1)
        dut.din_valid.value =0
    else:
        count = 0
        for i in range(len(b)):
            dut.b.value = int(b[i])
            dut.c.value = int(c[i])
            dut.din_valid.value = 1;
            await ClockCycles(dut.clk, 1)
            count +=1
            if(count ==burst_len):
                count =0
                dut.din_valid.value =0
                await ClockCycles(dut.clk, np.random.randint(10))
        dut.din_valid.value =0

async def read_data(dut, b,c,dout_width, dout_pt, thresh):
    index =0
    while(index < len(b)):
        valid = int(dut.dout_valid.value)
        if(valid==1):
            err = bool(dut.dout_error.value)
            gold = np.roots([1, b[index], c[index]])
            gold = np.sort(gold)
            if(np.iscomplex(gold).any()):
                assert (err==1) , "Out is complex but error dont appear! b={b:.4f},c={c:.4f}".format(b=b[index], c=c[index])
            else:
                assert (err==0) , "Error is not correct. b={b:.4f}, c={c:.4f}".format(b=b[index], c=c[index])
                out1 = int(dut.x1.value)
                out2 = int(dut.x2.value)
                out1, out2 = two_comp_unpack(np.array([out1, out2]), dout_width, dout_pt)
                out = np.sort([out1, out2])
                assert (np.abs(gold[0]-out[0])<thresh), "gold0: {gold0:.4f} ; x0: {x0:.4f}".format(gold0=gold[0], x0=out[0])
                assert (np.abs(gold[1]-out[1])<thresh), "gold1: {gold1:.4f} ; x1: {x1:.4f}".format(gold1=gold[1], x1=out[1])
            index +=1
        await ClockCycles(dut.clk,1)
            



