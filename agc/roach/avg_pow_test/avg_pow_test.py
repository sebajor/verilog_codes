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

def din_pkt(din, bin_pt, dtype='b'):
    """for this test we use input as 2bytes signed
        dat: numpy array with the mults
        bin_pt: binary point
        dtype: data type, only supported by struct b,h,i,q,B,H,I,Q
    """
    types = ['b','h','i', 'h']
    byte_size = types.index(dtype)+1
    dat = (din*2**bin_pt).astype(int)
    bin_data = struct.pack('>'+str(int(len(din)))+dtype, *dat)
    return bin_data


@cocotb.test()
async def avg_pow_test(dut, iters=2048, din_width=8,din_pt=0,delay_line=32, parallel=8):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dout_width = 2*din_width
    dout_pt = 2*din_pt
    np.random.seed(20)
    #test1 = await cte_test(dut,delay_line,iters, din_width,din_pt,dout_width,dout_pt,parallel,thresh=0.05)
    test2 = await sin_test(dut,delay_line,iters, din_width,din_pt,dout_width,dout_pt, thresh=0.5)


async def test(dut,dat,iters=128,delay_line=32,din_width=8,din_pt=0,dout_width=19,dout_pt=0, parallel=8,thresh=0.05):
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    din = BinaryValue()
    dut.rst <=0;
    dut.din_valid <=0
    dut.din <= 0
    data = dat.reshape([-1,parallel])
    #data = two_comp_pack(dat, din_width, din_int)
    await ClockCycles(dut.clk, 4) 
    mov = np.zeros(delay_line)
    gold_vals = []
    out_vals = []
    for i in range(len(data)):
        aux = din_pkt(data[i,:], din_pt, dtype='b')
        din.set_buff(aux)
        dut.din <= din
        dut.din_valid <=1
        mov = np.roll(mov,1)
        mov[0] = np.sum(data[i,:].astype(int)**2)
        await ClockCycles(dut.clk, 1)
        valid = dut.dout_valid.value
        gold_vals.append(int(np.sum(mov)/len(mov)/parallel))
        if(valid):
            out = np.array(int(dut.dout.value))
            out = out/2**(dout_pt)
            #out = two_comp_unpack(out, dout_width, dout_int)
            out_vals.append(out)
    for i in range(len(out_vals)-4):
        print("gold val: %0.5f"%(gold_vals[i]))
        print("out val: %0.5f"%(out_vals[i]))
        print("")
        assert (np.abs(gold_vals[i]-out_vals[i])<thresh), "fail in avg {}".format(i)

async def cte_test(dut,delay_line=32,iters=128, din_width=8,din_pt=7,dout_width=16,dout_pt=14,parallel=8, thresh=0.5):
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    dat = np.ones(iters)*8
    vals = await test(dut,dat,iters,delay_line,din_width,din_pt,dout_width,dout_pt, parallel, thresh)

async def sin_test(dut,delay_line=32,iters=128, din_width=8,din_pt=7,dout_width=16,dout_pt=14, parallel=8, thresh=0.5):
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    f = 30
    t = np.arange(iters)
    dat = 64*np.sin(2*np.pi*t*f/iters)
    vals = await test(dut,dat,iters,delay_line,din_width,din_pt,dout_width,dout_pt,parallel, thresh)
