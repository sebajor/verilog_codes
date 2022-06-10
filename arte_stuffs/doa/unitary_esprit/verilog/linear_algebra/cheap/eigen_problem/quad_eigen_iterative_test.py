import numpy as np
import cocotb, sys
sys.path.append('../../../')
from two_comp import two_comp_pack, two_comp_unpack
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock

###
### Author: Sebastian Jorquera
###

def eigen_gold(r11,r22,r12):
    r21 = r12
    lamb1 = (r11+r22+np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    lamb2 = (r11+r22-np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    eigvec1 = -(r11-lamb1)
    eigvec2 = -(r11-lamb2)
    eigfrac = r12
    return [lamb1, lamb2,eigvec1,eigvec2,eigfrac]

@cocotb.test()
async def quad_eigen_iterative(dut, iters=1024,din_width=16, din_pt=15, dout_width=16,dout_pt=13,
        thresh=0.05, cont=0, burst_len=10, rest=256):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    #setup dut
    dut.r11.value =0 
    dut.r12.value =0
    dut.r22.value =0
    dut.din_valid.value =0
    await ClockCycles(dut.clk,1)

    #create test data
    np.random.seed(19)

    r11 = np.random.random(iters)-0.5
    r22 = np.random.random(iters)-0.5
    r12 = np.random.random(iters)-0.5

    r11_b = two_comp_pack(r11, din_width, din_pt)
    r22_b = two_comp_pack(r22, din_width, din_pt)
    r12_b = two_comp_pack(r12, din_width, din_pt)

    data = [r11_b, r22_b, r12_b]
    gold = eigen_gold(r11,r22,r12)
    
    cocotb.fork(read_data(dut, gold, dout_width, dout_pt,thresh))
    await write_data(dut,data, cont, burst_len, rest)



async def write_data(dut, data, cont, burst, rest):
    if(cont):
        for i in range(len(data[0])):
            dut.r11.value = int(data[0][i])
            dut.r22.value = int(data[1][i])
            dut.r12.value = int(data[2][i])
            dut.din_valid.value =1
            await ClockCycles(dut.clk, 1)
        dut.din_valid.value =0
    else:
        count =0
        for i in range(len(data[0])):
            dut.band_in.value = int((i+1)%4)
            dut.r11.value = int(data[0][i])
            dut.r22.value = int(data[1][i])
            dut.r12.value = int(data[2][i])
            dut.din_valid.value =1
            await ClockCycles(dut.clk, 1)
            count += 1
            if(count == burst):
                dut.din_valid.value =0
                #await ClockCycles(dut.clk, np.random.randint(10))
                await ClockCycles(dut.clk, rest)
                count =0
        dut.din_valid.value =0


async def read_data(dut, gold, dout_width, dout_pt, thresh):
    ind = 0
    while(ind<len(gold[0])):
        valid = int(dut.dout_valid.value)
        error = int(dut.dout_error.value)
        if(error):
            #check the complex eigenval 
            ind +=1
            pass
        elif(valid):
            lamb1 = int(dut.lamb1.value); lamb2 = int(dut.lamb2.value)
            eigval1 = int(dut.eigen1_y.value); eigval2 = int(dut.eigen2_y.value);
            eigfrac = int(dut.eigen_x.value)
            outs = np.array([lamb1,lamb2,eigval1,eigval2,eigfrac])
            outs = two_comp_unpack(outs, dout_width, dout_pt)
            print("l1 \t gold: %.3f \t rtl: %.3f" %(gold[0][ind], outs[0]))
            print("l2 \t gold: %.3f \t rtl: %.3f" %(gold[1][ind], outs[1]))
            print("eig1 \t gold: %.3f \t rtl: %.3f" %(gold[2][ind], outs[2]))
            print("eig2 \t gold: %.3f \t rtl: %.3f" %(gold[3][ind], outs[3]))
            print("eig frac \t gold: %.3f \t rtl: %.3f" %(gold[2][ind], outs[2]))

            assert (np.abs(gold[0][ind]-outs[0])<thresh), "l1 error"
            assert (np.abs(gold[1][ind]-outs[1])<thresh), "l2 error"
            assert (np.abs(gold[2][ind]-outs[2])<thresh), "eig1 error"
            assert (np.abs(gold[3][ind]-outs[3])<thresh), "eig2 error"
            assert (np.abs(gold[4][ind]-outs[4])<thresh), "eig frac error"
            ind +=1
        await ClockCycles(dut.clk,1)

            

    
    
