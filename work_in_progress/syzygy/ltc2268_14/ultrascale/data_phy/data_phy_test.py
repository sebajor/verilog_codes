import cocotb
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer
from cocotb.clock import Clock
import numpy as np

async def ddr_writing(data, clock_interface, data_interface):
    for i in range(len(data)//2):
        await RisingEdge(clock_interface)
        data_interface.value = int(data[2*i])
        await FallingEdge(clock_interface)
        data_interface.value = int(data[2*i+1])


@cocotb.test()
async def data_phy_test(dut, bitslip=2, iters=120):
    bit_clk_period = 2 ##ns, for a 500mhz signal
    frame_clk_period = bit_clk_period*4 ##this gives the 125Mhz signal
    
    dut.sync_rst.value =0 
    dut.bitslip_count.value = bitslip+1 ##seems that the sim starts with one bitslip already
    

    bit_clk = Clock(dut.data_clk_bufio, bit_clk_period, units='ns')
    frame_clk = Clock(dut.data_clk_div, frame_clk_period, units='ns')
    
    await cocotb.start(bit_clk.start())   
    await cocotb.start(frame_clk.start())   

    #data = np.ones(iters, dtype=np.uint16)*32
    #data = (2** np.arange(16)).astype(np.uint16)
    data = np.random.randint(2**16, size=iters).astype(np.uint16)
     
    high_part = np.unpackbits((data>>8).astype(np.uint8)).reshape((-1,8))
    low_part = np.unpackbits(np.bitwise_and(data, 0xff).astype(np.uint8)).reshape((-1,8))
    
    data_bits = np.hstack((high_part, low_part))    ##(iters, 16) and the msb is at 0
    ##the ltc adc sends the msb first so we are ok..    
    serial0 = data_bits[:,::2].flatten()
    serial1 = data_bits[:,1::2].flatten()
    ##adding the bitslip
    serial0 = np.hstack((bitslip*[0], serial0))
    serial1 = np.hstack((bitslip*[0], serial1))
    cocotb.start_soon(ddr_writing(serial0, dut.data_clk_bufio, dut.adc_data_p0)) 
    cocotb.start_soon(ddr_writing(serial1, dut.data_clk_bufio, dut.adc_data_p1)) 
    await ClockCycles(dut.data_clk_div, 5)
    for i in range(len(data)):
        dout = dut.adc_data.value
        #print("gold: %i; rtl:%i"%(data[i], int(dout)))
        assert(data[i]==int(dout))
        #print(dout)
        await ClockCycles(dut.data_clk_div, 1)



       
    

     
