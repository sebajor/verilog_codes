import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import numpy as np

def gold_autoscale(dat1, dat2, bit_width,max_shift):
    bin1 = np.ceil(np.log2(dat1))
    bin2 = np.ceil(np.log2(dat2))
    shifts = bit_width-2-np.max([bin1,bin2], axis=0)
    ind = np.where(shifts>max_shift)
    shifts[ind] = max_shift
    return (shifts.astype(int))
    

@cocotb.test()
async def autoscale_test(dut, iters=128, din_width=32, max_shift=28):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.din_valid <= 0
    dut.din1 <=0; dut.din2 <= 0
    await ClockCycles(dut.clk, 3)
    np.random.seed(10)
    exp1 = np.random.randint(27, size=iters)
    exp2 = np.random.randint(27, size=iters)
    din1 = np.random.random(size=iters)*2**exp1
    din2 = np.random.random(size=iters)*2**exp2
    din1 = din1.astype(int)
    din2 = din2.astype(int)
    #din1 = np.random.randint(0, 2**15-1, size=iters)
    #din2 = np.random.randint(0, 2**15-1, size=iters)
    #din1 = np.ones(iters)*345353
    #din2 = np.ones(iters)*324808
    gold_shift = gold_autoscale(din1, din2, din_width, max_shift)
    count =0
    for i in range(iters):
        dut.din_valid <= 1
        dut.din1 <= int(din1[i])
        dut.din2 <= int(din2[i])
        await ClockCycles(dut.clk, 1)
        valid = int(dut.dout_valid.value)
        if(valid==1):
            rtl_dout1 = int(dut.dout1.value)
            rtl_dout2 = int(dut.dout2.value)
            rtl_shift = int(dut.shift_value.value)
            gold_dout1 = din1[count]<<(gold_shift[count])
            gold_dout2 = din2[count]<<(gold_shift[count])
            #print("shift: %i, gold: %i"%(rtl_shift, gold_shift[count]))
            #print(str(din1[count])+"\t"+str(din2[count])+"\n")
            #print("dout1: %i, gold: %i"%(rtl_dout1, gold_dout1))
            #print("dout2: %i, gold: %i\n"%(rtl_dout2, gold_dout2))
            assert (rtl_shift == gold_shift[count]), "Error shift: %i, gold: %i"%(rtl_shift, gold_shift[count])
            assert (rtl_dout1 == gold_dout1), "Error dout1: %i, gold: %i"%(rtl_dout1, gold_dout1)
            assert (rtl_dout2 == gold_dout2), "Error dout2: %i, gold: %i"%(rtl_dout2, gold_dout2)
            count +=1



