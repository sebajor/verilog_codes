import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
sys.path.append("../../cocotb_python")
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple

###
### Author: Sebastian Jorquera
###

def cov_calc(din):
    """ din = [acc_len, iters, n_inputs]
    """
    acc_len, iters, n_inputs = din.shape
    n_out = n_inputs*(n_inputs+1)/2
    out = np.zeros([int(iters), int(n_out)])
    count=0
    for i in range(n_inputs):
        for j in range(i, n_inputs):
            aux = np.sum(din[:,:,i]*din[:,:,j], axis=0)
            out[:, count] = aux
            count +=1
    print('aux')
    print(aux.shape)
    return out


@cocotb.test()
async def covariance_matrix_test(dut, n_inputs=4, iters=64, acc_len=64, din_width=8,
        din_pt=7, dout_width=32, thresh=0.2):
    ##localparams
    dout_pt = din_pt*2
    n_outputs = n_inputs*(n_inputs+1)/2
    
    ##configuration
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    #np.random.seed(2)
    
    dut.din.value = 0
    dut.din_valid.value =0
    dut.new_acc.value =0
    
    #create input values
    din_b = np.zeros([acc_len, iters, n_inputs])
    din = np.zeros([acc_len, iters, n_inputs])
    for i in range(n_inputs):
        din_ = np.random.random([acc_len, iters])-0.5
        din_b[:,:,i] = two_comp_pack(din_, din_width, din_pt)
        din[:,:,i] = din_
    gold = cov_calc(din)
    print(gold.shape)
    cocotb.fork(read_data(dut,gold, n_outputs, dout_width, dout_pt, thresh))
    await cont_write(dut, din_b, din_width)




async def cont_write(dut, din, bitwidth):
    for i in range(din.shape[1]):
        dut.new_acc.value = 1
        for j in range(din.shape[0]):
            dat = pack_multiple(din[j,i,:], din.shape[2], bitwidth)
            dut.din.value = int(dat)
            dut.din_valid.value = 1
            await ClockCycles(dut.clk,1)
            dut.new_acc.value =0
    

async def read_data(dut, gold, n_out, dout_width, dout_pt, thresh):
    await ClockCycles(dut.clk,1)
    count =0
    ##we let pass the first one, there is no data at the start
    while(1):
        valid = int(dut.dout_valid.value)
        if(valid):
            await ClockCycles(dut.clk,1)
            break
        await ClockCycles(dut.clk,1)
    while(count < gold.shape[0]):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)
            dout = unpack_multiple(dout, int(n_out), dout_width)
            dout = two_comp_unpack(dout, dout_width, dout_pt)
            for i in range(len(dout)):
                print("rtl: %.4f \t gold: %.4f"%(dout[i], gold[count,i]))
                assert (np.abs(dout[i]-gold[count,i])<thresh), "Error!"
            count +=1
        await ClockCycles(dut.clk, 1)

