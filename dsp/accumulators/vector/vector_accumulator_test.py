import cocotb, sys
sys.path.append('../../../cocotb_python/')
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from two_comp import two_comp_pack, two_comp_unpack

###
### Author: Sebastian Jorquera
###


@cocotb.test()
async def vector_accumulator_test(dut, din_width=16, dout_width=32, vec_len=64, iters=30,
        cont=0, back=3):
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.new_acc.value =0;
    dut.din.value =0;
    dut.din_valid.value =0;
    await ClockCycles(dut.clk,3)
    np.random.seed(10)
    
    acc_len = np.random.randint(low=1,high=10)
    #back = np.random.randint(low=1,high=10)
    print("Acc len: %i" %acc_len)
    data = -np.random.randint(2**(din_width-1)-1, size=[iters, acc_len, vec_len])
    gold = np.sum(data, axis=1)

    dat_b = two_comp_pack(data.flatten(), din_width, 0).reshape(data.shape)
    
    cocotb.fork(read_data(dut, gold.flatten(), vec_len, dout_width))
    await write_data(dut, dat_b, cont, back)



async def write_data(dut, data, cont, back):
    dut.new_acc.value = 1
    await ClockCycles(dut.clk,1)
    dut.new_acc.value =0
    if(cont):
        for i in range(data.shape[0]):
            for j in range(data.shape[1]):
                for k in range(data.shape[2]):
                    if(j==(data.shape[1]-1) and k==(data.shape[2]-1)):
                        dut.new_acc.value = 1
                    else:
                        dut.new_acc.value = 0
                    dut.din.value = int(data[i][j][k])
                    dut.din_valid.value = 1
                    await ClockCycles(dut.clk,1)
    else:
        for i in range(data.shape[0]):
            for j in range(data.shape[1]):
                for k in range(data.shape[2]):
                    dut.new_acc.value = 0
                    dut.din.value = int(data[i][j][k])
                    dut.din_valid.value = 1
                    await ClockCycles(dut.clk, 1)
                    if(j==(data.shape[1]-1) and k==(data.shape[2]-1)):
                        dut.din_valid.value = 0
                        await ClockCycles(dut.clk, back-1)
                        dut.new_acc.value = 1
                        await ClockCycles(dut.clk,1)
                    else:
                        dut.din_valid.value =0
                        await ClockCycles(dut.clk, back)

                    

async def read_data(dut, gold, vec_len, dout_width):
    count = 0
    while(count < vec_len):
        valid = int(dut.dout_valid.value)
        if(valid):
            count += 1
        await ClockCycles(dut.clk, 1)
    count = 0
    while(count<len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            dout = int(dut.dout.value)
            dout = two_comp_unpack(np.array(dout), dout_width, 0)
            print("%i \t rtl: %i \t gold: %i" %(count%vec_len, dout, gold[count]))
            assert (dout == gold[count]), "Error"
            count += 1
        await ClockCycles(dut.clk, 1)