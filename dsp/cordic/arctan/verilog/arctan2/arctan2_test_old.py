import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from two_comp import two_comp_pack, two_comp_unpack


@cocotb.test()
async def arctan2_test(dut, din_width=16, dout_width=16, iters=255, thresh=0.2):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_pt = din_width-1; dout_pt=dout_width-1
    #setup the dut
    dut.x <=0
    dut.y <=0
    dut.din_valid <=0
    await ClockCycles(dut.clk, 3)
    ##  
    np.random.seed(10)
    din1 = np.random.random(iters)-0.5
    din2 = np.random.random(iters)-0.5
    #write data
    await write_data(dut, din1, din2, din_width, dout_width, iters, thresh)


async def write_data(dut, din1, din2, din_width, dout_width, iters, thresh):
    gold = np.arctan2(din2, din1)/np.pi
    count = 0
    x = two_comp_pack(din1, din_width, din_width-1)
    y = two_comp_pack(din2, din_width, din_width-1)
    for i in range(len(x)):
        dut.x <= int(x[i])
        dut.y <= int(y[i])
        dut.din_valid <=1;
        await ClockCycles(dut.clk, 1)
        dut.din_valid <=0;
        for j in range(25):
            await ClockCycles(dut.clk, 1);
            valid = int(dut.dout_valid.value)
            sys_rdy = int(dut.sys_ready.value)
            if(valid==1):
                out = np.array(int(dut.dout.value))
                out = two_comp_unpack(out, dout_width, dout_width-1)
                assert (np.abs(gold[count]-out)), 'Error!'
                #print('gold: %.4f \t rtl: %.4f' %(gold[count], out))
                count += 1
            if(sys_rdy):
               break
