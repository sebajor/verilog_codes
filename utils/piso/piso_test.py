import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.clock import Clock

###
###     Author: Sebastian Jorquera
###

def unpack_data(data, mult, nbits=32):
    out = np.zeros(mult)
    for i in range(mult):
        aux = int(data>>(nbits*i))
        mask = 2**nbits-1
        dat = aux & mask
        out[i] = dat
    return out

def pack_data(data, mult, nbits=32):
    out = 0
    for i in range(mult):
        out += (int(data[i]))<<(i*nbits)
    return out

@cocotb.test()
async def piso_test(dut, iters=200, din_width=512, dout_width=64,multiplex_in=16,
        multiplex_out=2, burst_write_len=3, sleep_write=64, burst_read_len=18, sleep_read=10):
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    #dout_width = int(din_width//multiplex)
    np.random.seed(10)
    dut.rst.value =0

    data = np.arange(iters*multiplex_in)
    #cocotb.fork(read_data(dut, data, dout_width, multiplex_out))
    #await simple_write(dut, data, dout_width,  multiplex_in)
    cocotb.fork(burst_read(dut, data, dout_width, multiplex_out,
        burst_read_len, sleep_read))
    await burst_write(dut, data, dout_width, multiplex_in, 
            multiplex_out, burst_write_len, sleep_write)



async def read_data(dut, gold, dout_width, multiplex):
    dut.dout_ready.value = 1
    await ClockCycles(dut.clk,2)
    count =0
    while(count < len(gold)):
        valid = int(dut.dout_valid.value)
        if(valid):
            out = int(dut.dout.value)
            dout = unpack_data(out, multiplex, nbits=int(dout_width/multiplex))
            for i in range(len(dout)):
                print(str(dout[i])+"\t"+str(gold[count]))
                assert (dout[i]==gold[count]) , "Error! "
                count +=1
        await ClockCycles(dut.clk,1)


async def burst_read(dut, gold, dout_width, multiplex_out, burst_len, sleep_cycles):
    dut.dout_ready.value = 1
    count_ready =0
    await ClockCycles(dut.clk,2)
    count =0
    while(count < len(gold)):
        ready = dut.dout_ready.value
        dut.dout_ready.value = 1
        valid = int(dut.dout_valid.value)
        if(valid and ready):
            count_ready+=1
            out = int(dut.dout.value)
            dout = unpack_data(out, multiplex_out, nbits=int(dout_width/multiplex_out))
            for i in range(len(dout)):
                print("gold: %.2f \t rtl: %.2f"%(gold[count], dout[i]))
                assert (dout[i]==gold[count]) , "Error! "
                count +=1
        if(count_ready==burst_len):
            count_ready =0
            dut.dout_ready.value = 0
            for i in range(sleep_cycles):
                await ClockCycles(dut.clk,1)
        await ClockCycles(dut.clk,1)

async def simple_write(dut, data, dout_width, multiplex):
    dut.din_valid.value =0
    dut.din.value =0
    await ClockCycles(dut.clk, 2)
    for i in range(int(len(data)//multiplex)):
        dat = pack_data(data[i*multiplex:(i+1)*multiplex], multiplex, nbits=dout_width)
        dut.din.value = dat
        dut.din_valid.value = 1
        await ClockCycles(dut.clk, 1)



async def burst_write(dut, data, dout_width, multiplex_in, multiplex_out, burst_len, sleep_write):
    dut.din_valid.value =0
    #dut.dout_ready <=0
    dut.din.value =0
    en_read =0
    await ClockCycles(dut.clk, 2)
    for i in range(len(data)//multiplex_in):
        if(i%burst_len==0):
            for j in range(sleep_write):
                dut.din_valid.value = 0
                #dut.dout_ready <= 1
                await ClockCycles(dut.clk, 1)
        dat = pack_data(data[i*multiplex_in:(i+1)*multiplex_in], 
                multiplex_in, nbits=int(dout_width/multiplex_out))
        dut.din.value = dat
        dut.din_valid.value = 1
        #dut.dout_ready <=0
        await ClockCycles(dut.clk, 1)

        


    


    
