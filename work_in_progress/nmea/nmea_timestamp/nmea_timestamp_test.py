import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
from cocotb.clock import Clock

###
### Author: Sebastian Jorquera
###
@cocotb.test()
async def nmea_timestamp_test(dut, clk_freq_mhz=25, baud_rate=115200):
    msg = 'GARBAGE...$GPZDA,235959,14,10,2003,00,00*4F'
    #setup dut
    clk_period = 1./clk_freq_mhz*10**3
    clk = Clock(dut.clk, clk_period, 'ns')
    cocotb.fork(clk.start())
    dut.rst.value = 0
    dut.i_pps.value = 0
    dut.i_uart_rx.value = 1
    await ClockCycles(dut.clk, 10)
    cocotb.fork(pps_signal(dut, clk_period/5))
    cocotb.fork(transmitter(dut, msg+msg, baud_rate))
    await read_data(dut, 3)




async def pps_signal(dut, period):
    while(1):
        await Timer(30, 'ms')
        dut.i_pps.value = 1
        await Timer(1, 'us')
        dut.i_pps.value = 0

async def transmitter(dut, msg, baud_rate):
    baud_clk = int(1./baud_rate*10**9)  #ns
    msg_ascii = list(msg.encode('ascii'))
    while(1):
        for word in msg_ascii:
            #generate start condition
            dut.i_uart_rx.value = 0;
            await Timer(baud_clk, 'ns')
            bin_word = bin(word)
            for i in range(8):
                dut.i_uart_rx.value = int((word>>i)&1)
                await Timer(baud_clk, 'ns')
            ##stop condition
            dut.i_uart_rx.value=1
            await Timer(2*baud_clk, 'ns')
        await Timer(10, 'ms')

async def read_data(dut, iters):
    for i in range(iters):
        await RisingEdge(dut.pps)
        sec = int(dut.sec.value)
        minute = int(dut.min.value)
        hr = int(dut.hr.value)
        print("%i : %i :%i"%(hr,minute,sec))

