import cocotb, struct
import numpy as np
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue

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
async def parallel_macc_test(dut, parallel=8, din_width=8, din_int=1,
                            w_width=16, w_int=3, w_addrs=64, dout_width=32,
                            dout_int=10, iters=50, thresh=0.1):
    types = ['b','h','i', 'q']
    din_type = types[int(din_width/8-1)]
    w_type = types[int(w_width/8-1)]

    clk = Clock(dut.clk, 10, "ns")
    cocotb.fork(clk.start())
    np.random.seed(2)
    ##
    din_pt = din_width-din_int
    w_pt = w_width-w_int
    dout_pt = dout_width-dout_int
    din = BinaryValue()
    weight = BinaryValue()
    dout = BinaryValue()
    
    gold_vals = []
    out_vals = []
    dut.rst <= 0
    acc = 0
    for i in range(iters):
        gold = np.zeros(w_addrs)
        for j in range(w_addrs):
            dat_din = (np.random.random(parallel)-0.5)*2**(din_int-1)
            dat_w = -(np.random.random(parallel)-0.5)*2**(w_int-1)
            #dat_din = (np.ones(parallel)-0.1)*(2**(din_int-1))
            #dat_w = (np.ones(parallel)-0.9)*(2**(w_int-1))
            din_q = (dat_din*2**din_pt).astype(int)/2**din_pt
            w_q = (dat_w*2**w_pt).astype(int)/2**w_pt
            #acc = np.sum(dat_din*dat_w)+acc
            acc = np.sum(din_q+w_q)+acc
            #print(dat_w)
            #print(dat_w*2**(w_pt))
            din_b = din_pkt(dat_din, din_pt, dtype='b')
            w_b = din_pkt(dat_w, w_pt, dtype='h')

            din_quant = np.array(struct.unpack('>'+str(parallel)+din_type,din_b))/2**din_pt
            w_quant = np.array(struct.unpack('>'+str(parallel)+w_type,w_b))/2**w_pt
            gold[j] = np.sum(din_quant*w_quant)
            #gold_vals.append(np.sum(din_quant*w_quant))

            din.set_buff(din_b)
            weight.set_buff(w_b)
            dut.din <= din
            dut.weight <= weight
            dut.din_valid <= 1
            await ClockCycles(dut.clk, 1)
            valid = dut.dout_valid.value;
            if(int(valid)):
                out = int(dut.dout.value)
                out = np.array(out)
                out = two_comp_unpack(out, dout_width, dout_int)
                out_vals.append(out)
            #print(int(dut.parallel_macc_inst.sum_out.value))
        gold_vals.append(gold)
    wait = 15
    for i in range(wait):
        valid = dut.dout_valid.value;
        if(int(valid)):
            out = int(dut.dout.value)
            out = np.array(out)
            out = two_comp_unpack(out, dout_width, dout_int)
            out_vals.append(out)
        await ClockCycles(dut.clk, 1)
        #sum_deb = int(dut.parallel_macc_inst.sum_out.value)
        #sum_deb = two_comp_unpack(np.array(sum_deb), 16+3,7)
        #print(sum_deb)

    gold_vals = np.array(gold_vals)
    """
    for i in range(len(gold_vals)):
        print(gold_vals[i])
    """
    #print("ACC: "+str(acc))
    for i in range(len(out_vals)):
        assert (np.abs(np.sum(gold_vals[i])-out_vals[i])<thresh), "fail in {}".format(i)
        #print("Phyton Output "+str(np.sum(gold_vals[i])))
        #print("Verilog Output: "+str(out_vals[i]))
    print("Pass!")




