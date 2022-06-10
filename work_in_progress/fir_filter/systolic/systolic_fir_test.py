import numpy as np
import matplotlib.pyplot as plt
import cocotb, sys
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge
from cocotb.clock import Clock
import matplotlib.pyplot as plt
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack

###
### Author: Sebastian Jorquera
###


class fir_filter():
    def __init__(self, coeffs):
        self.coeffs = coeffs
        self.dly_line = np.zeros(len(coeffs))

    def next_value(self, din):
        self.dly_line = np.roll(self.dly_line, 1)
        self.dly_line[0] = din
        dout = np.sum(self.dly_line*self.coeffs)#np.dot(self.dly_line, self.coeffs)
        #print(self.dly_line*self.coeffs)
        return dout


@cocotb.test()
async def systolic_fir_test(dut, din_width=16,din_pt=14,weight_width=16,
        weight_pt=14, weight_size=8, dout_width=32,dout_pt=28, iters=128,
        thresh=10**-3):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    np.random.seed(12)
    #create the filter coefs
    # w = np.random.randn(int(weight_size/2))
    # w = np.hstack([w,w])    #symmetric
    w = np.loadtxt('w_ex')
    #gen_coeffs(w, weight_width, weight_pt)
    fir = fir_filter(w)

    ##initialize the signals
    dut.din.value =0;
    dut.din_valid.value =0
    din = np.random.random(iters)-0.5

    #print(din)
    #din = np.ones(iters)*0.5
    await ClockCycles(dut.clk, 2)
    cocotb.fork(read_data(dut,din,fir,dout_width,dout_pt, weight_size,iters, thresh))
    din_val = two_comp_pack(din, din_width, din_pt)
    for i in range(iters):
        dut.din.value = int(din_val[i])
        dut.din_valid.value =1
        await ClockCycles(dut.clk, 1)


async def read_data(dut,din, fir, dout_width, dout_pt, weight_size,iters, thresh):
    count =0
    #fill the dly tap
    #for i in range(weight_size):
    #    gold = fir.next_value(din[i])
    while(count< iters):
        valid = int(dut.dout_valid.value)
        if(valid):
            out = int(dut.dout.value)
            out = two_comp_unpack(np.array(out), dout_width, dout_pt)
            gold = fir.next_value(din[count])
            count +=1
            #print("gold:%.3f  rtl:%.3f"%(gold, out))
            #print("%i \n"%(count))
            assert (np.abs(out-gold)<thresh) , "Error! "
        await ClockCycles(dut.clk,1)
