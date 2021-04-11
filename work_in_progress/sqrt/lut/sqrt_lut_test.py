import cocotb, struct
import numpy as np
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles


@cocotb.test()
async def sqrt_lut_test(dut, din_width=16, din_pt=10, dout_width=16, dout_pt=12, iters=32, thresh=0.05):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_pt
    np.random.seed(10)
    din = np.random.rand(iters)*2**(din_int-1)
    din_bin = (din*2**(din_pt)).astype(int)
    dut.din_valid <= 0
    dut.din <=0
    await ClockCycles(dut.clk, 5)
    out_vals = []
    for i in range(len(din)):
        dut.din <= int(din_bin[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk, 1)
        valid = dut.dout_valid.value
        if(valid):
            out = int(dut.dout.value)
            out = out/(2.**dout_pt)
            out_vals.append(out)
    gold_vals = np.sqrt(din)
    for i in range(len(out_vals)):
        print("gold val: %.4f \t verilog val: %.4f" %(gold_vals[i], out_vals[i]))
        assert (np.abs(gold_vals[i]-out_vals[i])<thresh), "fail in avg {}".format(i)

            
