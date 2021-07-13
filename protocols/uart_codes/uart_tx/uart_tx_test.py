import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, FallingEdge, Timer, RisingEdge
from cocotb.clock import Clock


@cocotb.test()
async def uart_tx_test(dut, clk_freq=25000000, baud_rate=115200):
    clk_period = 1./clk_freq*10**9
    clk = Clock(dut.clk, clk_period, 'ns')
    cocotb.fork(clk.start())
    dut.axis_tvalid <= 0;
    dut.axis_tdata  <= 0;
    await ClockCycles(dut.clk, 4)
    msg = "hello world"
    recv_msg = ""
    for word in msg:
        ready = int(dut.axis_tready.value)
        if(ready):
            word_ascii = ord(word)
            dut.axis_tvalid <=1;
            dut.axis_tdata <= int(word_ascii)
            await ClockCycles(dut.clk,1)
            dut.axis_tvalid <= 0;
            recv_byte = await send_byte(dut,word_ascii,baud_rate)
            recv_msg = recv_msg+chr(recv_byte)
            await ClockCycles(dut.clk,3)
    print("Sent phrase: "+msg) 
    print("Recv phrase: "+recv_msg)
    #for word in msg_ascii:
        #print(chr(word))
    
        

async def send_byte(dut,word_ascii, baud_rate):
    baud_clk = int(1./baud_rate*10**9)  #ns
    #wait for the start condition
    await FallingEdge(dut.tx_data)
    await Timer(0.5*baud_clk, 'ns') #to take the sample at the middle of the bit
    msg = np.ones(8)
    for i in range(8):
        await Timer(baud_clk, 'ns')
        msg[i] = int(dut.tx_data.value)
    await Timer(baud_clk*0.5, 'ns')
	#finish condition
    await RisingEdge(dut.tx_data)
    await Timer(baud_clk, 'ns')
    #print(msg)
    recv_data = np.packbits(msg.astype(int), bitorder='little')  #get the value
    return recv_data


    
