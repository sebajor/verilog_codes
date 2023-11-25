import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
import numpy as np

###
### Author: Sebastian Jorquera
###

class mmcme4_base():

    def __init__(self, dut, mmcm_name, clkout_sim=[0,1]):
        """
        MMCME4-base simulator. Given the parameters in the HDL it reads them and 
        generate the desired clocks relations.

        The indices in clkout_sim indicates what clocks should be simulated, the rest 
        is forced to zero
        """
        self.mmcm = getattr(dut, mmcm_name)

        self.clkin_period = float(self.mmcm.CLKIN1_PERIOD.value)    ##in ns
        self.clkin_freq = 1./(self.clkin_period*1e-9)                    ##in Hz
        self.M = int(self.mmcm.CLKFBOUT_MULT_F.value)
        self.D = int(self.mmcm.DIVCLK_DIVIDE.value) 
        self.phase_vco = float(self.mmcm.CLKFBOUT_PHASE.value)      ##in deg
        
        ##VCO parameters
        self.vco_freq = self.clkin_freq*self.M/self.D
        self.vco_period = 1./self.vco_freq
        self.vco_phase_time = self.phase_vco/360*self.vco_period

        ##set the lock in zero
        self.mmcm.LOCKED.value = 0
        self.get_simclk_info(clkout_sim)

    def get_simclk_info(self,clkout_sim):
        ##now we can start the rest of the clocks
        clk_out_params = ['CLKOUT%i_DIVIDE_F', 'CLKOUT%i_PHASE', 'CLKOUT%i']    #always assume 50% dutycycle...
        self.clk_sim_list = []
        for i in range(7):
            clk_obj = {}
            clk_out = i
            if(i in clkout_sim):
                clk_obj['divide'] = int(getattr(self.mmcm, clk_out_params[0]%clk_out).value)
                clk_obj['phase'] = float(getattr(self.mmcm, clk_out_params[1]%clk_out).value)
                clk_obj['clk_port'] = getattr(self.mmcm, clk_out_params[2]%clk_out)
                clk_obj['freq'] = self.vco_freq/clk_obj['divide']
                clk_obj['phase_time'] = clk_obj['phase']/360*1./clk_obj['freq']
                self.clk_sim_list.append(clk_obj)
            else:
                clk_port = getattr(self.mmcm, clk_out_params[2]%clk_out)
                clk_port.value = 0
        

    async def start_output_clocks(self):
        """
        To make this work, the signal that goes into CLKIN1 should be started
        """
        ###to have a common reference
        await RisingEdge(self.mmcm.CLKIN1)
        ## we awat the timer to get the phase offset, to be in sync with the VCO
        if(self.vco_phase_time!=0):
            await Timer(self.phase_vco_time*1e9, units='ns') 
        
        ## now we order by the phase in time, to start the clocks
        simclk_phases = [x['phase_time'] for x in self.clk_sim_list]
        ind = np.argsort(simclk_phases)
        acc_phase = 0
        for i in ind:
            clk_info = self.clk_sim_list[i]
            clk_phase = clk_info['phase_time']*1e9   #ns
            if((clk_phase-acc_phase)!=0):
                await Timer(clk_phase-acc_phase, units='ns')
                print('awaited %.2f'%(clk_phase-acc_phase))
                acc_phase += clk_phase
            clk_period = 1./clk_info['freq']*1e9
            print("Clock freq: %.2f MHz, Period: %.2f ns"%(clk_info['freq']/1e6, clk_period))
            clk_sim = Clock(clk_info['clk_port'], clk_period, units='ns')
            await cocotb.start(clk_sim.start())
        await ClockCycles(self.mmcm.CLKIN1, 10)
        self.mmcm.LOCKED.value = 1

             

        




