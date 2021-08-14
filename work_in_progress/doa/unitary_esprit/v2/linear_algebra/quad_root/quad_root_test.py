import numpy as np
import struct, cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from two_comp import two_comp_pack, two_comp_unpack

@cocotb.test()
async def quad_root_test(dut, iters=256, din_width=16, din_pt=14,
        dout_width = 16, dout_pt=13, thresh=0.1):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    np.random.seed(10)
    b = np.random.random(iters)-0.5
    c = np.random.random(iters)-0.5
    #b = np.ones(iters)*0.271321
    #c = np.ones(iters)*0.145072
    #c[1::2] = c[::2]*0.5
    #c[::2] = c[1::2]*0.6 
    b_bin = two_comp_pack(b, din_width, din_pt)
    c_bin = two_comp_pack(c, din_width, din_pt)
    #initialize the inputs
    dut.b <=0
    dut.c<=0
    dut.din_valid <=0
    await ClockCycles(dut.clk, 5)
    x1_vals = []
    x2_vals = []
    #write data into the dut
    index =0;
    for i in range(iters):
        dut.b <= int(b_bin[i])
        dut.c <= int(c_bin[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk,1)
        valid = int(dut.dout_valid.value)
        if(valid):
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
                #print("x1_gold: %.4f \t x1_fpga: %.4f" %(gold[0], out[0]))
                #print("x2_gold: %.4f \t x2_fpga: %.4f" %(gold[1], out[1]))
                #print("")
            index +=1
                    


                
