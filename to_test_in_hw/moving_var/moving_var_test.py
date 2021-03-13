import cocotb, struct
import numpy as np
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import ClockCycles



def two_comp_pack(values, n_bits, n_int):
    """ Values are a numpy array witht the actual values
        that you want to set in the dut port
        n_bits: number of bits
        n_int: integer part of the representation
    """
    bin_pt = n_bits-n_int
    quant_data = (2**bin_pt*values).astype(int)
    ovf = (quant_data>2**(n_bits-1)-1)&(quant_data<2**(n_bits-1))
    if(ovf.any()):
        raise "Cannot represent one value with that representation"
    mask = np.where(quant_data<0)
    quant_data[mask] = 2**(n_bits)+quant_data[mask]
    return quant_data


def two_comp_unpack(values, n_bits, n_int):
    """Values are integer values (to test if its enough to take
    get_value_signed to obtain the actual value...
    """
    bin_pt = n_bits-n_int
    mask = values>2**(n_bits-1)-1 ##negative values
    out = values.copy()
    out[mask] = values[mask]-2**n_bits
    out = 1.*out/(2**bin_pt)
    return out


@cocotb.test()
async def moving_average_test(dut, iters=128, win_len=16, din_width=32, din_point=31):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_point
    #test1 = await cte_test(dut, 50, 10)
    np.random.seed(10)
    dat = np.random.random(20)-0.5
    test2 = await mov_test(dut,dat,win_len,din_width, din_int, thresh=0.05)


async def mov_test(dut, dat, win_len=16, din_width=32, din_int=31, thresh=0.05):
    dut.rst <=0;
    dut.din_valid <=0
    dut.din <= 0
    data = two_comp_pack(dat, din_width, din_int)
    await ClockCycles(dut.clk, 4)
    mov = np.zeros(win_len)
    avg_gold = []
    var_gold = []
    out_avg = []
    out_var = []
    for i in range(len(dat)):
        dut.din <= int(data[i])
        dut.din_valid <= 1
        mov = np.roll(mov,1)
        mov[0] = dat[i]
        await ClockCycles(dut.clk,1)
        valid = dut.dout_valid.value
        avg_gold.append(np.sum(mov)/len(mov))
        var_gold.append(np.sum(mov**2)/len(mov)-avg_gold[-1]**2)
        if(valid):
            out = np.array(int(dut.moving_avg.value))
            out = two_comp_unpack(out, din_width, din_int)
            out_avg.append(out)
            out = np.array(int(dut.moving_var.value))
            out = two_comp_unpack(out, 2*din_width, 2*din_int)
            out_var.append(out)
    for i in range(len(out_avg)-4):
        #print("gold avg: %0.5f \t out avg: %0.5f"%(avg_gold[i], out_avg[i+4]))
        #print("gold var: %0.5f \t out var: %0.5f"%(var_gold[i], out_var[i+4]))
        #print("")
        assert (np.abs(avg_gold[i]-out_avg[i+4])<thresh), "fail in avg {}".format(i)
        assert (np.abs(var_gold[i]-out_var[i+4])<thresh), "fail in var {}".format(i)

async def cte_test(dut, cycles, cte):
    dut.rst <=0;
    dut.din_valid <= 0;
    dut.din <= 0;
    await ClockCycles(dut.clk, 4)
    dut.rst <=0;
    dut.din_valid <= 1;
    dut.din <= 0;
    await ClockCycles(dut.clk, 10) 
    dut.din_valid <= 1;
    dut.din <=cte
    out_vals = []
    for i in range(cycles):
        await ClockCycles(dut.clk,1)
        #valid = dut.dout_valid.value
        #if(valid):
            #print(int(dut.dout.value))
            #out_vals.append(out)
    return 1


