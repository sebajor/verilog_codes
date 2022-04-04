import cocotb, struct, sys
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
sys.path.append('../../../../../cocotb_python/')
from two_comp import two_comp_pack, two_comp_unpack




@cocotb.test()
async def arctan_test(dut, din_width=16, dout_width=16, iters=128, thresh=0.1):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_pt = din_width-1; dout_pt = dout_width-1
    np.random.seed(10)
    din1 = np.random.random(iters)
    din2 = np.random.random(iters)
    
    ##reorder the input data to have the higher value in x
    x = din1
    y = din2
    ind = np.where(din1<din2)
    x[ind] = din2[ind]
    y[ind] = din1[ind]
    gold = np.arctan(y/x)/np.pi
    x_bin = two_comp_pack(x, din_width, din_pt)
    y_bin = two_comp_pack(y, din_width, din_pt)
    count =0
    ##
    dut.y.value =0
    dut.x.value =0
    dut.din_valid.value =0
    await ClockCycles(dut.clk, 3)
    cocotb.fork(write_data(dut, x_bin,y_bin, din_width, din_pt))
    await read_data(dut, x,y,dout_width, dout_pt, thresh)


async def read_data(dut, x,y,dout_width, dout_pt, thresh):
    gold = np.arctan(y/x)/np.pi
    count=0
    for i in range(20*len(x)):
        await ClockCycles(dut.clk, 1)
        valid = int(dut.dout_valid.value)
        if(valid==1):
            out = np.array(int(dut.dout.value))
            out = two_comp_unpack(out, dout_width, dout_pt)
            print('gold:%.5f \t out:%.5f' %(gold[count], out))
            assert (np.abs(gold[count]-out)< thresh) , 'Error!'
            count+=1

async def write_data(dut, x_bin,y_bin, din_width, din_pt):
    dut.x.value = int(x_bin[0])
    dut.y.value = int(y_bin[0])
    dut.din_valid.value = 1
    await ClockCycles(dut.clk, 1)
    dut.din_valid.value =0
    for i in range(1,len(x_bin)):
        await RisingEdge(dut.sys_ready)
        dut.x.value = int(x_bin[i])
        dut.y.value = int(y_bin[i])
        dut.din_valid.value = 1
        await ClockCycles(dut.clk,1)
        dut.din_valid.value =0
        #while(1):
        #    sys_rdy = int(dut.sys_ready.value)
        #    if(sys_rdy):
        #        break
        #    await ClockCycles(dut.clk, 1)
