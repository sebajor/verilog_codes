import numpy as np
import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
import uesprit
from scipy.fftpack import fft
import matplotlib.pyplot as plt

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


def create_clean_data(freqs=[10], phases=[30], acc_len=5, vec_len=64,snr=40, xspace=0.05):
    data = uesprit.multi_source(freqs=freqs, phases=phases, length=acc_len*vec_len, dft_len=vec_len, x_space=xspace)
    data = uesprit.add_noise(data, snr)
    dat0 = data[0,:].reshape([acc_len,vec_len])
    dat1 = data[1,:].reshape([acc_len,vec_len])
    spec0 = fft(dat0, axis=1)
    spec1 = fft(dat1, axis=1)
    return [spec0, spec1]



@cocotb.test()
async def v_uesprit_la_test(dut, acc_len=5, vec_len=64, din_width=16, 
        din_pt=15, dout_width=16, dout_pt=13, xspace=0.01):
    freqs = np.ones(20)*59
    phases = np.linspace(-60, 60, 13)
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_pt
    dut.new_acc <=0
    dut.din1_re<=0; dut.din1_im<=0;
    dut.din2_re<=0; dut.din2_im<=0;
    dut.din_valid<=0
    dut.shift <= 4
    await ClockCycles(dut.clk,1)
    spec0, spec1 = create_clean_data(freqs=[freqs[0]], phases=[phases[0]],acc_len=acc_len, vec_len=vec_len,xspace=xspace)
    spec0 = 1.*spec0/(np.max(np.sqrt(spec0*np.conj(spec0))))
    spec1 = 1.*spec1/(np.max(np.sqrt(spec1*np.conj(spec1))))
    
    ####there is a problem here!! somewhere there is an overflow if the input
    ### is big, i test it with this and works good--> the main suspect is the 
    ## accumulator in the correlation!
    ##its right the max value now is 8192 in the wavescope!
    l1, l2, e1,e2,e_frac = await write_data(dut,spec0,spec1,din_width,din_pt,dout_width,dout_pt) 
    l1, l2, e1,e2,e_frac = await write_data(dut,spec0,spec1,din_width,din_pt,dout_width,dout_pt) 
    
    r11,r12,r22 = uesprit.uesprit_matrix(np.array([spec0, spec1]))
    gold_l1, gold_l2, gold_e1,gold_e2, gold_frac = uesprit.uesprit_la(r11,r12.real,r22)
    
    print("gold l1:%.4f \t rtl l1:%.4f"%(gold_l1[int(freqs[0])], l1[int(freqs[0])]))
    print("gold l2:%.4f \t rtl l2:%.4f"%(gold_l2[int(freqs[0])], l2[int(freqs[0])]))
    print("gold e1:%.4f \t rtl e1:%.4f"%(gold_e1[int(freqs[0])]/gold_frac[int(freqs[0])],e1[int(freqs[0])]/e_frac[int(freqs[0])]))
    print("gold e2:%.4f \t rtl e2:%.4f"%(gold_e2[int(freqs[0])]/gold_frac[int(freqs[0])],e2[int(freqs[0])]/e_frac[int(freqs[0])]))
    
    """
    for i in range(len(l1)):
        print(i)
        print("gold l1:%.4f \t rtl l1:%.4f"%(gold_l1[i], l1[i]))
        print("gold l2:%.4f \t rtl l2:%.4f"%(gold_l2[i], l2[i]))
        print("gold e1:%.4f \t rtl e1:%.4f"%(gold_e1[i], e1[i]))
        print("gold e2:%.4f \t rtl e2:%.4f"%(gold_e2[i], e2[i]))
        print("gold frac:%.4f \t rtl frac:%.4f"%(gold_frac[i], e_frac[i]))
    """

async def write_data(dut, dat1, dat2, din_width, din_pt, dout_width, dout_pt):
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    acc_len, vec_len = dat1.shape
    dut.new_acc<=1
    lamb1 = []; lamb2=[]; eig1=[]; eig2=[]; eig_frac=[]
    for i in range(acc_len):
        din1re = two_comp_pack(dat1[i,:].real, din_width, din_int)
        din1im = two_comp_pack(dat1[i,:].imag, din_width, din_int)
        din2re = two_comp_pack(dat2[i,:].real, din_width, din_int)
        din2im = two_comp_pack(dat2[i,:].imag, din_width, din_int)
        for j in range(vec_len):
            dut.din1_re <= int(din1re[j])
            dut.din1_im <= int(din1im[j])
            dut.din2_re <= int(din2re[j])
            dut.din2_im <= int(din2im[j])
            dut.din_valid <=1
            await ClockCycles(dut.clk,1)
            dut.new_acc <=0;
            valid = int(dut.dout_valid.value)
            if(valid):
                l1 = np.array(int(dut.lamb1.value))
                l2 = np.array(int(dut.lamb2.value))
                e1 = np.array(int(dut.eigen1_y.value))
                e2 = np.array(int(dut.eigen2_y.value))
                e_frac = np.array(int(dut.eigen_x))
                outs = np.array([l1,l2,e1,e2,e_frac])
                outs = two_comp_unpack(outs, dout_width, dout_int)
                lamb1.append(outs[0]); lamb2.append(outs[1]);
                eig1.append(outs[2]); eig2.append(outs[3]);
                eig_frac.append(outs[4])
    out_vals = [lamb1, lamb2,eig1,eig2,eig_frac]
    return out_vals

