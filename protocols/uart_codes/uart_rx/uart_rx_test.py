import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, FallingEdge, Timer, RisingEdge
from cocotb.clock import Clock

###
### Author: Sebastian Jorquera
###
@cocotb.test()
async def uart_rx_test(dut, clk_freq_mhz=25, baud_rate=115200):
    #msg = 'GARBAGE...$GPZDA,112010,14,10,2003,00,00*4F'
    msg = "hello world"
    clk_period = 1./clk_freq_mhz*10**3
    clk = Clock(dut.clk, clk_period, 'ns')
    cocotb.fork(clk.start())
    dut.rst.value = 0;
    dut.rx_data.value=1;
    dut.uart_rx_tready.value=1;
    await ClockCycles(dut.clk, 10)
    cocotb.fork(transmitter(dut, msg, baud_rate))
    await read_data(dut, msg)
    await ClockCycles(dut.clk, 20)

    
async def transmitter(dut, msg, baud_rate):
    baud_clk = int(1./baud_rate*10**9)  #ns
    msg_ascii = list(msg.encode('ascii'))
    for word in msg_ascii:
        #generate start condition
        dut.rx_data.value = 0;
        await Timer(baud_clk, 'ns')
        bin_word = bin(word)
        for i in range(8):
            dut.rx_data.value = int((word>>i)&1)
            await Timer(baud_clk, 'ns')
        ##stop condition
        #dut.rx_data.value=0
        #await Timer(baud_clk*0.5, 'ns')
        dut.rx_data.value=1
        await Timer(2*baud_clk, 'ns')

async def read_data(dut, msg):
    count =0
    msg_rtl = ""
    while(count < len(msg)):
        valid = int(dut.uart_rx_tvalid.value)
        if(valid):
            dout = int(dut.uart_rx_tdata.value)
            dout = chr(dout)
            print(dout)
            msg_rtl+=dout
            count +=1
        await ClockCycles(dut.clk, 1)
    print("gold msg: "+msg)
    print("rtl  msg: "+msg_rtl)
    assert (msg == msg_rtl)


    


           
