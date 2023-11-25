import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
from cocotb.clock import Clock
import sys
sys.path.append('../../../../../cocotb_python/')
from mmcme4_base import mmcme4_base
import numpy as np


@cocotb.test()
async def clock_alignment_test(dut, bitslip=3/4, precision=3):
    print(dir(dut.clock_alignment_inst.genblk1.mmcm_dclk))  #it seems that I need to access to it to populate the mmcm correctly 
    mmcme_name = 'clock_alignment_inst.genblk1.mmcm_dclk'
    clkout_sim = [0,1]

    ##configure the default signals
    dut.async_rst.value = 0
    dut.sync_rst.value =0 
    dut.enable.value = 0
    
    mmcm = mmcme4_base(dut, mmcme_name, clkout_sim=clkout_sim)

    print("Clkin freq:%.2f ; Clkin period: %.2f"%(mmcm.clkin_freq/1e6, mmcm.clkin_period))
    print("ClkVCO  freq:%.2f; ClkVCO period: %.2f"%(mmcm.vco_freq/1e6, mmcm.vco_period))
    print("Clkout0 freq: %.2f MHz; Clkout0 period: %.2f ns"%(mmcm.clk_sim_list[0]['freq']/1e6, 1./mmcm.clk_sim_list[0]['freq']*1e9))
    print("Clkout1 freq. %.2f MHz; Clkout1 period: %.2f ns"%(mmcm.clk_sim_list[1]['freq']/1e6, 1./mmcm.clk_sim_list[1]['freq']*1e9))

    print("The shift on the VCO in %.2f deg causes a delay of %.2f ns"%(mmcm.phase_vco, mmcm.vco_phase_time*1e9))
    print("Since the data clock is %.2f, then shift causes that the clock is at the eye of the data"%(1./mmcm.clk_sim_list[0]['freq']*1e9))
    
    ##to keep consistency I will create the clock with mmcme parameters
    bit_clk = mmcm.clkin_period
    data_clk = Clock(dut.data_clock_p, bit_clk, units='ns')
    await cocotb.start(data_clk.start())

    ## and the frame clock also...
    ## The data clock should be 90deg from the frame clock and the data
    frame_clk = Clock(dut.frame_clock_p, bit_clk*4, units='ns')
    await Timer(np.round(bit_clk/4., precision), units='ns')
    if(bitslip!=0):
        bitslip_delay = np.round(bit_clk*bitslip, precision)
        print(bitslip_delay)
        await Timer(bitslip_delay, units='ns') 
    await cocotb.start(frame_clk.start())
    
    ##start the clocks of the mmcm
    await mmcm.start_output_clocks()
    #    
    await ClockCycles(dut.data_clock_p, 10)
    dut.enable.value = 1
    await ClockCycles(dut.data_clock_p, 20)
    print(dut.iserdes_dout.value)
    print(int(dut.bitslip_count.value))


