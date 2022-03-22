import numpy as np
import cocotb, sys
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
sys.path.append('../../../cocotb_python')
from two_comp import two_comp_pack, two_comp_unpack, pack_multiple, unpack_multiple
from itertools import cycle

###
###     Author: Sebastian Jorquera
###

@cocotb.test()
async def gbe_write_packetizer(dut, iters=16, din_width=8, multiplex_in=16, 
        dout_width=8, multiplex_out=1, burst_write=200,
        sleep_write=2048, pkt_len=109, sleep_cycles=10):
    #setup dut
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())

    dut.din0.value =0;  dut.din1.value=0
    dut.din2.value =0;  dut.din3.value=0
    dut.din4.value =0;  dut.din5.value=0
    dut.din6.value =0;  dut.din7.value=0
    dut.din8.value =0;  dut.din9.value=0
    dut.dinA.value =0;  dut.dinB.value=0
    dut.dinC.value =0;  dut.dinD.value=0
    dut.dinE.value =0;  dut.dinF.value=0

    dut.din_valid.value =0;
    dut.rst.value =0
    dut.pkt_len.value = pkt_len-1
    dut.sleep_cycles.value = sleep_cycles-1

    #data = np.arange(burst_write*multiplex_in).reshape([-1,multiplex_in])
    data = np.random.randint(2**8-1, size=(burst_write*multiplex_in)).reshape([-1, multiplex_in])
    cocotb.fork(read_data(dut,data, burst_write*multiplex_in, multiplex_out, din_width, pkt_len))
    await write_data(dut, data, din_width, multiplex_in,iters, burst_write, sleep_write)




async def read_data(dut,gold,write_size, multiplex_out, din_width, pkt_len):
    counter =0
    #gold = np.arange(write_size)
    gold = np.hstack(([ 0xdd,0xcc,0xbb,0xaa,
                        0,  0,   0,   0,
                        0xdd,0xcc,0xbb,0xaa,
                        0,  0,   0,   0], gold.flatten()))
    gold = cycle(gold)
    await ClockCycles(dut.clk,1)
    while(1):
        full = int(dut.fifo_full.value)
        valid = int(dut.tx_valid.value)
        eof = int(dut.tx_eof)
        if(full):
            raise Exception("Fifo Full!!")
        if((counter%pkt_len==0) and counter!=0):
            assert (eof==1), 'eof is not high when it should!'
        if(eof):
            assert (valid ==1) , 'eof high but valid not!!!'
        if(valid):
            tx0 = int(dut.tx_data.value)
            aux0 = next(gold)
            print("gold: %.2f \t rtl:%.2f" %(aux0, tx0))
            assert (tx0==aux0), "Error"
        await ClockCycles(dut.clk,1)


async def write_data(dut, data, din_width, multiplex_in,iters, burst_write, sleep_write):
    for i in range(iters):
        dut.din0.value =0; dut.din1.value=0
        dut.din2.value =0; dut.din3.value=0
        dut.din4.value =0; dut.din5.value=0
        dut.din6.value =0; dut.din7.value=0
        dut.din8.value =0; dut.din9.value=0
        dut.dinA.value =0; dut.dinB.value=0
        dut.dinC.value =0; dut.dinD.value=0
        dut.dinE.value =0; dut.dinF.value=0
        

        dut.din_valid.value =0
        await ClockCycles(dut.clk, sleep_write)
        
        dut.din0.value =0xdd; dut.din1.value=0xcc
        dut.din2.value =0xbb; dut.din3.value=0xaa
        dut.din4.value =0; dut.din5.value=0
        dut.din6.value =0; dut.din7.value=0
        dut.din8.value =0xdd; dut.din9.value=0xcc
        dut.dinA.value =0xbb; dut.dinB.value=0xaa
        dut.dinC.value =0; dut.dinD.value=0
        dut.dinE.value =0; dut.dinF.value=0
        
        #dut.din.value = (0xaabbccdd+((0xaabbccdd)<<64))
        dut.din_valid.value = 1
        await ClockCycles(dut.clk, 1)
        for j in range(data.shape[0]):
            dut.din0.value = int(data[j,0]); dut.din1.value = int(data[j,1])
            dut.din2.value = int(data[j,2]); dut.din3.value = int(data[j,3])
            dut.din4.value = int(data[j,4]); dut.din5.value = int(data[j,5])
            dut.din6.value = int(data[j,6]); dut.din7.value = int(data[j,7])
            dut.din8.value = int(data[j,8]); dut.din9.value = int(data[j,9])
            dut.dinA.value = int(data[j,10]);dut.dinB.value = int(data[j,11])
            dut.dinC.value = int(data[j,12]);dut.dinD.value = int(data[j,13])
            dut.dinE.value = int(data[j,14]);dut.dinF.value = int(data[j,15])
            #dat = pack_multiple(data[j,:], multiplex_in, din_width)
            #dut.din.value = int(dat)
            dut.din_valid.value = 1
            await ClockCycles(dut.clk,1)

            

    

