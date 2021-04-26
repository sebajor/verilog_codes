import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def unsig_acc_test(dut, din_width=16, dout_width=32, acc_len=10,iters=128):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.din <=0
    dut.din_valid <=0
    dut.acc_done <=0
    await ClockCycles(dut.clk, 1)

    #data
    dout_vals =[]
    data = np.random.randint(0,2**8,[acc_len, iters])
    for i in range(iters):
        dut.acc_done <=1
        for j in range(acc_len):
            dut.din <= int(data[j,i])
            dut.din_valid <=1
            await ClockCycles(dut.clk, 1)
            dut.acc_done <= 0;
            valid = int(dut.dout_valid.value)
            if(valid):
                dout_vals.append(int(dut.dout.value))
    gold_vals = np.sum(data, axis=0)
    for i in range(len(dout_vals)-1):
        #print("gold: %i \t rtl:%i"%(gold_vals[i], dout_vals[i+1]))
        assert ((dout_vals[i+1]-gold_vals[i])==0), "error in {}".format(i)
