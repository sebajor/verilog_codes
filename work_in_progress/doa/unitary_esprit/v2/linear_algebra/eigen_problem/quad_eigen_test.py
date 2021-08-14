import cocotb
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
import numpy as np
from two_comp import two_comp_pack, two_comp_unpack


def eigen_gold(r11,r22,r12):
    r21 = r12
    lamb1 = (r11+r22+np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    lamb2 = (r11+r22-np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    eigvec1 = -(r11-lamb1)
    eigvec2 = -(r11-lamb2)
    eigfrac = r12
    return [lamb1, lamb2,eigvec1,eigvec2,eigfrac]

@cocotb.test()
async def eigen_test(dut, din_width=16, din_pt=15, dout_width=16,dout_pt=13,
        iters=128, thresh=0.05):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    dut.r11 <= 0; dut.r22 <= 0; dut.r12 <= 0;
    dut.din_valid <=0;
    await ClockCycles(dut.clk, 4)
    np.random.seed(10)
    r11 = np.random.random(iters)-0.5
    r12 = np.random.random(iters)-0.5
    r22 = np.random.random(iters)-0.5
    await write_data(dut, r11,r22,r12, din_width, din_pt, dout_width, dout_pt, thresh)


async def write_data(dut,r11, r22,r12,din_width, din_pt, dout_width, dout_pt, thresh):
    r11_b = two_comp_pack(r11, din_width, din_pt)
    r22_b = two_comp_pack(r22, din_width, din_pt)
    r12_b = two_comp_pack(r12, din_width, din_pt)
    [l1_gold, l2_gold, eig1_gold, eig2_gold, frac_gold] = eigen_gold(r11,r22,r12)
    index =0;
    for i in range(len(r11)):
        dut.r11 <= int(r11_b[i])
        dut.r12 <= int(r12_b[i])
        dut.r22 <= int(r22_b[i])
        dut.din_valid <= 1;
        await ClockCycles(dut.clk, 1)
        valid = int(dut.dout_valid.value)
        error = int(dut.dout_error.value)
        if(error==1):
            ##check the complex eigen val
            index +=1
            pass
        elif(valid==1):
            lamb1 = int(dut.lamb1.value); lamb2 = int(dut.lamb2.value)
            eigval1 = int(dut.eigen1_y.value); eigval2 = int(dut.eigen2_y.value); 
            eigfrac = int(dut.eigen_x.value)
            outs = np.array([lamb1,lamb2,eigval1,eigval2,eigfrac])
            outs = two_comp_unpack(outs, dout_width, dout_pt)
            assert (np.abs(l1_gold[index]-outs[0])<thresh), "l1 error: {}".format(index)
            assert (np.abs(l2_gold[index]-outs[1])<thresh), "l2 error: {}".format(index)
            assert (np.abs(eig1_gold[index]-outs[2])<thresh), "eig1 error: {}".format(index)
            assert (np.abs(eig2_gold[index]-outs[3])<thresh), "eig2 error: {}".format(index)
            assert (np.abs(frac_gold[index]-outs[4])<thresh), "eig2 error: {}".format(index)
            #print("gold_l1: %.4f \t out_l1: %.4f" %(l1_gold[index], outs[0]))
            #print("gold_l2: %.4f \t out_l2: %.4f" %(l2_gold[index], outs[1]))
            #print("gold_eig1: %.4f \t out_eig1: %.4f" %(eig1_gold[index], outs[2]))
            #print("gold_eig2: %.4f \t out_eig2: %.4f" %(eig2_gold[index], outs[3]))
            #print("gold_frac: %.4f \t out_frac: %.4f" %(frac_gold[index], outs[4]))
            #print("")
            index +=1
        


