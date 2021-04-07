import cocotb, struct
import numpy as np
import matplotlib.pyplot as plt
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

def dout_unpack(dout, bin_pt, parallel, dtype='h'):
    """ 
    """
    types = ['b','h','i', 'h']
    byte_size = types.index(dtype)+1
    length = parallel*byte_size-len(dout)
    dout = length*b'\x00'+dout
    out = np.array(struct.unpack('>'+str(parallel)+dtype, dout))
    out = out/2**bin_pt
    return out


@cocotb.test()
async def avg_pow_test(dut, iters=16384, din_width=8,din_pt=7,delay_line=32, parallel=8,
            coef_width=16, coef_pt=8,gain_width=16,gain_pt=8):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    ref_pow = np.array([0.125])
    error_coef = np.array([2])
    #np.random.seed(20)
    #dat = np.ones(iters)*0.3
    #test1 = await test(dut,dat,ref_pow,error_coef, iters, din_width,din_pt,delay_line, parallel,
    #        coef_width, coef_pt,gain_width,gain_pt)
    #test2 = await test_sin(dut,ref_pow,error_coef, iters, din_width,din_pt,delay_line, parallel,
    #        coef_width, coef_pt,gain_width,gain_pt)
    test3 = await test_mod(dut,ref_pow,error_coef, iters, din_width,din_pt,delay_line, parallel,
            coef_width, coef_pt,gain_width,gain_pt)

async def test_sin(dut, ref_pow, error_coef, iters=2048, din_width=8,din_pt=7,delay_line=32, parallel=8,
            coef_width=16, coef_pt=8,gain_width=16,gain_pt=8):
    f = 30
    t = np.arange(iters)
    dat = 0.9*np.sin(2*np.pi*t*f/iters)
    vals = await test(dut,dat,ref_pow,error_coef, iters, din_width,din_pt,delay_line, parallel,
            coef_width, coef_pt,gain_width,gain_pt)

async def test_mod(dut, ref_pow, error_coef, iters=2048, din_width=8,din_pt=7,delay_line=32, parallel=8,
            coef_width=16, coef_pt=8,gain_width=16,gain_pt=8):
    f = 30
    t = np.arange(iters)
    dat = 0.9*np.sin(2*np.pi*t*f/iters)*np.exp(-1*t/iters) 
    vals = await test(dut,dat,ref_pow,error_coef, iters, din_width,din_pt,delay_line, parallel,
            coef_width, coef_pt,gain_width,gain_pt)



async def test(dut, dat,ref_pow, error_coef, iters=2048, din_width=8,din_pt=7,delay_line=32, parallel=8,
            coef_width=16, coef_pt=8,gain_width=16,gain_pt=8):
    din_int = din_width-din_pt
    coef_int = coef_width-coef_pt
    gain_int = gain_width-gain_pt
    dout_width = din_width+gain_width
    dout_pt = din_pt+gain_pt
    dout_int = dout_width-dout_pt
    din = BinaryValue()
    ref_pow = two_comp_pack(ref_pow, 2*din_width, 2*din_int)
    error_coef = two_comp_pack(error_coef,coef_width, coef_int)
    dut.ref_pow <= int(ref_pow);
    dut.error_coef <= int(error_coef)
    dut.rst <=0;
    dut.din_valid <=0
    dut.din <= 0
    data = dat.reshape([-1,parallel])
    #data = two_comp_pack(dat, din_width, din_int)
    await ClockCycles(dut.clk, 4) 
    mov = np.zeros(delay_line)
    gold_vals = []
    out_vals = np.zeros([len(data), parallel])
    print("data len:"+str(len(data)))
    for i in range(len(data)):
        aux = din_pkt(data[i,:], din_pt, dtype='b')
        din.set_buff(aux)
        dut.din <= din
        dut.din_valid <=1
        #mov = np.roll(mov,1)
        #mov[0] = np.sum(data[i,:].astype(int)**2)
        await ClockCycles(dut.clk, 1)
        dout0=int(dut.dout0.value); dout1=int(dut.dout1.value); dout2=int(dut.dout2.value); dout3=int(dut.dout3.value);
        dout4=int(dut.dout4.value); dout5=int(dut.dout5.value); dout6=int(dut.dout6.value); dout7=int(dut.dout7.value);
        dout = np.array([dout0,dout1,dout2,dout3,dout4,dout5,dout6,dout7])
        dout = two_comp_unpack(dout.astype(int), din_width+16, 9)
        out_vals[i,:] = dout
    print("out!")
    out_vals = out_vals[:,::-1].flatten()
     
    fig = plt.figure()
    ax1 = fig.add_subplot(211)
    ax2 = fig.add_subplot(212)
    ax1.plot((dat*2.**8).astype(int)/2**7)
    ax2.plot(out_vals)
    plt.savefig("asd.png")
    plt.show()


    """
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
        """


