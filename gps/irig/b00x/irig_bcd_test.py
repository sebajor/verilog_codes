import numpy as np
import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb.clock import Clock
from irig_pattern import irig_pattern
import datetime


@cocotb.test()
async def irig_bcd_test(dut,clk_freq=0.1, duration=5):
    one_sec = clk_freq*10**6
    secure_factor = 1.05
    debounce = 4

    clk = Clock(dut.clk, int(1./clk_freq), units='us')
    cocotb.fork(clk.start())
    dut.rst <=0
    dut.calibrate <=0
    dut.cont <=0
    dut.one_count <=int(one_sec/10**2*0.5*secure_factor)
    dut.zero_count <=int(one_sec/10**2*0.2*secure_factor)
    dut.id_count <=int(one_sec/10**2*0.8*secure_factor)
    dut.debounce <= debounce
    dut.din <=0
    
    await ClockCycles(dut.clk, 4)
    dut.calibrate <= 1

    date = datetime.datetime(2021, 8, 16, 22, 28, 55)
    cocotb.fork(write_irig_data(dut, clk_freq, duration, date=date))
    await ClockCycles(dut.clk,1)
    await Timer(duration, 'sec')
    sec_rtl = int(dut.sec.value)
    min_rtl = int(dut.min.value)
    hr_rtl = int(dut.hr.value)
    day_rtl = int(dut.day.value)
    print(date)
    print(date.timetuple().tm_yday)
    print("rtl data")
    print("day: %i  \t hr: %i"%(day_rtl, hr_rtl))
    print("min: %i  \t sec: %i"%(min_rtl, sec_rtl))


async def write_irig_data(dut, clk_freq, duration, date=None):
    data = irig_pattern(clk_freq, sim_dur=duration,timecode=date)
    data = data.astype(int)
    print(data)
    aux = datetime.datetime.now()
    #print(aux)
    #print(aux.timetuple().tm_yday)
    for i in range(len(data)):
        dat = data[i]
        #print(dat)
        dut.din <= 1
        if(dat == 0):
            await Timer(2, 'ms')
            dut.din <= 0
            await Timer(8, 'ms')
        if(dat == 1):
            await Timer(5, 'ms')
            dut.din <=0
            await Timer(5, 'ms')
        if(dat ==2):
            await Timer(8, 'ms')
            dut.din <=0
            await Timer(2, 'ms')










