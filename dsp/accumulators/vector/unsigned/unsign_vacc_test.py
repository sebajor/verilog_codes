import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

@cocotb.test()
async def unsign_vacc_test(dut, din_width=16, dout_width=32, vec_len=64, iters=30,
        cont=0, back=8):
    cocotb.fork(Clock(dut.clk, 10, units='ns').start())
    dut.new_acc.value =0;
    dut.din.value =0;
    dut.din_valid.value =0;
    await ClockCycles(dut.clk,3)
    #np.random.seed(10)
    
    acc_len = np.random.randint(low=1,high=10)
    #back = np.random.randint(low=1,high=10)
    print("Acc len: %i" %acc_len)
    data = np.random.randint(2**16-1, size=[iters, acc_len, vec_len])
    gold = np.sum(data, axis=1)
    
    cocotb.fork(read_data(dut, gold.flatten(), vec_len))
    await write_data(dut, data, cont, back)



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

                    

async def read_data(dut, gold, vec_len):
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
            print("%i \t rtl: %i \t gold: %i" %(count%vec_len, dout, gold[count]))
            assert (dout == gold[count]), "Error"
            count += 1
        await ClockCycles(dut.clk, 1)
