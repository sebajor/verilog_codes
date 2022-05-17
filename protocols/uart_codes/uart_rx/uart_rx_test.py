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
    clk_period = 1./clk_freq*10**3
    clk = Clock(dut.clk, clk_period, 'ns')
    cocotb.fork(clk.start())
    dut.rst.value = 0;
    dut.rx_data.value=1;
    dut.uart_rx_tready.value=1;
    await ClockCycles(dut.clk, 10)

    
async def transmitter(dut, msg, baud_rate):
    baud_clk = int(1./baud_rate*10**9)  #ns
    #generate start condition
    dut.rx_data.value = 0;
    await Timer(baud_clk, 'ns')
    msg_ascii = list(msg.encode('ascii'))
    for word in range(msg):
        for i in range(8):
            dut.rx_data.value = int((word>>i)&1)
            await Timer(baud_clk, 'ns')
        ##stop condition
        dut.rx_data.value=0
        await Timer(baud_clk*0.2, 'ns')
        dut.rx_data.value=1
        await Timer(baud_clk*1.5, 'ns')

async def read_data(dut, msg):
    


           
