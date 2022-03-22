import numpy as np
import cocotb, sys
from cocotb.clock import Clock 
from cocotb.triggers import ClockCycles
sys.path.append('../../cocotb_python/')
from two_comp import two_comp_pack, two_comp_unpack

###
###     Author: Sebastian Jorquera
###

@cocotb.test()
async def dsp48_macc_test(dut, din_width=16, dout_width=48, 
        acc_len=10, iters=128, thresh=0.01):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.din1 <=0; dut.din2 <=0;
    dut.din_valid <=0;
    dut.new_acc <=0;
    await ClockCycles(dut.clk, 1)
    din_pt = din_width-1
    dout_pt = 2*din_pt
    
    #din1 = np.ones([acc_len, iters])*-0.5
    #din2 = np.ones([acc_len, iters])*0.8
    np.random.seed(13)
    din1 = np.random.random([acc_len, iters])-0.5
    din2 = np.random.random([acc_len, iters])-0.5
    
    gold = np.sum(din1*din2, axis=0)
    
    din1_b = two_comp_pack(din1, din_width,din_pt)
    din2_b = two_comp_pack(din2, din_width,din_pt)

    cocotb.fork(read_data(dut, gold, dout_width, dout_pt, thresh))
    await cont_write(dut, din1_b, din2_b, acc_len)
    


async def cont_write(dut, din1, din2, acc_len):
    for i in range(din1.shape[1]):
        dut.new_acc <= 1
        for j in range(din1.shape[0]):
            dut.din1 <= int(din1[j,i])
            dut.din2 <= int(din2[j,i])
            dut.din_valid <= 1
            await ClockCycles(dut.clk,1)
            dut.new_acc <=0
    

async def read_data(dut, gold, dout_width, dout_pt, thresh):
    await ClockCycles(dut.clk, 1)
    count =0;
    ##we let pass the first one, there is no data at start
    while(1):
        valid = int(dut.dout_valid.value)
        if(valid):
            await ClockCycles(dut.clk,1)
            break
        await ClockCycles(dut.clk,1)
    while(count<len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)
            dout = two_comp_unpack(np.array(dout), dout_width, dout_pt)
            print("rtl: %.4f \t gold:%.4f"%(dout,gold[count]))
            assert (np.abs(dout-gold[count])<thresh), 'Error!'
            count += 1
        await ClockCycles(dut.clk, 1)

