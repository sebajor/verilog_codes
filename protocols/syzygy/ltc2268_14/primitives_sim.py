
class bufr():
    def __init__(self):
        ##


class idelay():
    def __init__(self):



class mmcme4():
    
    def __init__(self, dut, mmcm_name, clkout_sim=[0,1]):
        """
        clkout_sim: this are the clocks that will be simulated, the others 
        will be set at 0

        parameters:
            clkbout_mult_f:(2-128)             --> M
            divclk_DIVIDE:(1-106)
            clkfbout_phase
            clkin1_period
            clkout0_divide_f:1-128      --> O
            CLKOUT0_DUTY_CYCLE:
            CLKOUT0_PHASE: phase offset in deg
            i in (1-6)
            CLKOUTi_DIVIDE: (1-128)
            CLKOUTi_DUTY_CYCLE
            CLKOUTi_PHASE
        ports:
            CLKFBIN: feedback clock input to the mmcm
            CLKFBOUT: feedback output
            CLKFBOUTB: feedback output inverted
            CLKIN1: input clock
            CLKOUTi: clock out i
            CLKOUTiB: inverted clock i
            (i goes from 0 to 3, 4,5 and 6 doesnt have the inverted one)
            LOCKED
            PWRDWN: powerdown
            RST

        Fvco = F_clkinxM/D
        Fout = F_clkinxM/D/O

        FVCO must be (800-1600)
        """
        self.mmcm = getattr(dut, mmcm_name)
        self.clkin_period = int(self.mmcm.CLKIN1_PERIOD.value)
        self.M = int(self.mmcm.CLKFBOUT_MULT_F.value)
        self.D = int(self.mmcm.DIVCLK_DIVIDE.value)
        self.phase_vco = float(self.mmcm.CLKFBOUT_PHASE.value)  ##check

        self.clkin_freq = 1./(self.clkin_period*1e-9)
        self.vco_freq = self.clkin_freq*self.M/self.D

        print('VCO frequency at %f MHz'%(self.vco/1e6))
        
        clk_out_params = ['CLKOUT%I_DIVIDE_F', 'CLKOUT%I_PHASE', 'CLKOUT%I']    #always assume 50% dutycycle...
        self.clkout = []
        for clk_out in clkout_sim:
            clk_obj = {}
            clk_obj['divide'] = int(getattr(self.mmcm, clk_out_params[0]%clk_out).value)
            clk_obj['phase'] = float(getattr(self.mmcm, clk_out_params[1]%clk_out).value)
            clk_obj['clk_port'] = getattr(self.mmcm, clk_out_params[2]%clk_out)

            


        


         
        
        
        

            




