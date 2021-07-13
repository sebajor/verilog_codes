import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import numpy as np


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


def eigen_gold(r11,r22,r12):
    r21 = r12
    lamb1 = (r11+r22+np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    lamb2 = (r11+r22-np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    eigvec1 = -(r11-lamb1)
    eigvec2 = -(r11-lamb2)
    eigfrac = r12
    return [lamb1, lamb2,eigvec1,eigvec2,eigfrac]



@cocotb.test()
async def eigen_test(dut, din_width=16, din_pt=15, dout_width=16, dout_pt=13, iters=128, thresh=0.05):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    din_int = din_width-din_pt
    dout_int = dout_width-dout_pt
    dut.r11 <= 0; dut.r22 <= 0; dut.r12 <= 0;
    dut.din_valid <=0;
    await ClockCycles(dut.clk, 4)
    
    np.random.seed(20)
    r11_val = np.random.random(iters)*2-1#-0.2
    r12_val = np.random.random(iters)*2-1#0.3
    r22_val = np.random.random(iters)*2-1#-0.5

    r11 = two_comp_pack(r11_val, din_width, din_int)
    r12 = two_comp_pack(r12_val, din_width, din_int)
    r22 = two_comp_pack(r22_val, din_width, din_int)

    gold_lamb1 = []; gold_lamb2 =[]; 
    gold_eig1 = []; gold_eig2 = []; gold_frac = [];
    out_lamb1 = []; out_lamb2 =[]; 
    out_eig1 = []; out_eig2 = []; out_frac = [];
    for i in range(iters):
        dut.r11 <= int(r11[i])
        dut.r12 <= int(r12[i])
        dut.r22 <= int(r22[i])
        dut.din_valid <= 1
        await ClockCycles(dut.clk, 1)
        valid = int(dut.dout_valid)
        [l1 , l2, eig1,eig2,eig_frac] = eigen_gold(r11_val[i], r22_val[i], r12_val[i])
        gold_lamb1.append(l1) ; gold_lamb2.append(l2);
        gold_eig1.append(eig1); gold_eig2.append(eig2); gold_frac.append(eig_frac)
        if(valid):
            lamb1 = int(dut.lamb1.value); lamb2 = int(dut.lamb2.value)
            eigval1 = int(dut.eigen1_y.value); eigval2 = int(dut.eigen2_y.value); 
            eigfrac = int(dut.eigen_x.value)
            outs = np.array([lamb1,lamb2,eigval1,eigval2,eigfrac])
            outs = two_comp_unpack(outs, dout_width, dout_int)
            out_lamb1.append(outs[0]); out_lamb2.append(outs[1])
            out_eig1.append(outs[2]); out_eig2.append(outs[3]); out_frac.append(outs[4])
    for i in range(len(out_lamb1)):
        #print("gold_l1: %.4f \t out_l1: %.4f" %(gold_lamb1[i], out_lamb1[i]))
        #print("gold_l2: %.4f \t out_l2: %.4f" %(gold_lamb2[i], out_lamb2[i]))
        #print("gold_eig1: %.4f \t out_eig1: %.4f" %(gold_eig1[i], out_eig1[i]))
        #print("gold_eig2: %.4f \t out_eig2: %.4f" %(gold_eig2[i], out_eig2[i]))
        #print("gold_frac: %.4f \t out_frac: %.4f" %(gold_frac[i], out_frac[i]))
        #print("")
        assert (np.abs(gold_lamb1[i]-out_lamb1[i])<thresh), "l1 error: {}".format(i)
        assert (np.abs(gold_lamb2[i]-out_lamb2[i])<thresh), "l2 error: {}".format(i)
        assert (np.abs(gold_eig1[i]-out_eig1[i])<thresh), "eig1 error: {}".format(i)
        assert (np.abs(gold_eig2[i]-out_eig2[i])<thresh), "eig2 error: {}".format(i)
        assert (np.abs(gold_frac[i]-out_frac[i])<thresh), "eig2 error: {}".format(i)
        
