import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def write_cont(dut, din_width, dout_width, vec_len, iters):
    """
    data = [vec_len, acc_len];
    """
    gold = np.zeros(vec_len)
    dut.new_acc <=1
    await ClockCycles(dut.clk, 1)
    for i in range(iters):
        acc_len = np.random.randint(1, 32)
        data = (np.abs(np.random.randn(acc_len, vec_len))*2**12).astype(int)
        #data = np.arange(vec_len)
        gold_new = np.sum(data, axis=0)
        #gold_new = np.arange(64)*acc_len
        din = data.flatten()
        dut.new_acc <=0
        gold = np.append(gold,gold_new)
        for j in range(len(din)-1):
            dut.new_acc <=0
            dut.din <=int(din[j])
            dut.din_valid <= 1
            await ClockCycles(dut.clk, 1)
            valid = int(dut.dout_valid.value)
            if(valid):
                ##the first set of values are zeros
                out= np.array(int(dut.dout.value))
                assert (out == gold[0]), ("Error, rtl:%i gold:%i"%(out, gold[0]))
                gold = np.delete(gold,0)
        dut.din <= int(din[-1])
        dut.new_acc <= 1
        await ClockCycles(dut.clk, 1)
        valid = int(dut.dout_valid.value)
        if(valid):
            ##the first set of values are zeros
            out= np.array(int(dut.dout.value))
            assert (out == gold[0]), ("Error, rtl:%i gold:%i"%(out, gold[0]))
            gold = np.delete(gold,0)


@cocotb.test()
async def signed_vacc_test(dut, din_width=16, dout_width=32, vec_len=64, iters=30):
    #initialize varibles
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.new_acc <=0;
    dut.din <=0;
    dut.din_valid <=0;
    await ClockCycles(dut.clk,3)
    np.random.seed(10)
    dut.new_acc <=1;
    await ClockCycles(dut.clk,1)
    await write_cont(dut, din_width, dout_width, vec_len, iters)

