import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
import numpy as np
from mmcme4_base import mmcme4_base


@cocotb.test()
async def mmcme4_base_test(dut, sim_time=10, clkout_sim=[0,1]):
    clkin_period = float(dut.CLKIN1_PERIOD.value)
    ##for the sake of the simulation we are going to create the input clock
    clk_in = Clock(dut.CLKIN1, clkin_period, units='ns')
    await cocotb.start(clk_in.start()) 

    mmcme = mmcme4_base(dut, mmcm_name='mmcme4_base_inst', clkout_sim=clkout_sim)
    await mmcme.start_output_clocks()
    
    await ClockCycles(dut.CLKIN1, 50)
    
        

    

