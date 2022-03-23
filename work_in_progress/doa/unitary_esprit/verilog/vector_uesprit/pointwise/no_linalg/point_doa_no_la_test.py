import cocotb, sys
from scipy.fftpack import fft
sys.path.append('../../../../')
sys.path.append('../../../../high_level_sim')
import numpy as np
from itertools import cycle
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from two_comp import two_comp_pack, two_comp_unpack
import uesprit


###
### Author: Sebastian Jorquera
###

class gen_data():
    def __init__(self, dft_len=64,iters=10, freqs=[10,30], phases=[20, 50], 
            amplitude=[0.2,1 ], noise_std=10**-3):
        """ Its a good idea to control the snr with the noise std
        """
        data0 = np.zeros(dft_len, dtype=complex)
        data1 = np.zeros(dft_len, dtype=complex)
        t = np.arange(dft_len)
        for freq, phase, amp in zip(freqs, phases,amplitude):
            dat0 = amp*np.exp(1j*(2*np.pi*freq*t/dft_len))
            dat1 = amp*np.exp(1j*(2*np.pi*freq*t/dft_len+np.deg2rad(phase)))
            data0 = data0+dat0
            data1 = data1+dat1
        data0 = np.repeat(data0, iters).reshape([-1, iters]).T
        data1 = np.repeat(data1, iters).reshape([-1, iters]).T
        #add some noise
        data0 = data0+np.sqrt(noise_std)*(np.random.normal(size=data0.shape)+
                1j*np.random.normal(size=data0.shape))
        data1 = data1+np.sqrt(noise_std)*(np.random.normal(size=data0.shape)+
                1j*np.random.normal(size=data0.shape))
        self.antenna0 = fft(data0, axis=1)
        self.antenna1 = fft(data1, axis=1)
        self.sample0 = cycle(self.antenna0.flatten())
        self.sample1 = cycle(self.antenna1.flatten())
        
    def get_sample(self):
        """Obtain the samples for the antennas and also put a little randomness
        """
        dat0 = self.sample0.next()*np.random.normal(0.9, 0.05)
        dat1 = self.sample0.next()*np.random.normal(0.9, 0.05)
        return dat0, dat1
    
    def get_spectrum(self):
        spec0 = 10*np.log10(np.abs(np.abs(self.antenna0)))
        spec1 = 10*np.log10(np.abs(np.abs(self.antenna1)))
        return spec0, spec1


@cocotb.test()
async def point_doa_no_la(dut, iters=10, acc_len=10, vec_len=64,din_width=16, din_pt=14, 
        dout_width=32, dout_pt=16, cont=1, burst_len=10):
    ##hyper params for the data generation
    freqs = [20, 33]
    phases = [70, 33]
    amps = [0.8, 0.2]
    
    ##
    clk = Clock(dut.clk, 1)
    cocotb.fork(clk.start())
    
    #setup the dut 
    dut.din1_re.value = 0
    dut.din1_im.value = 0
    dut.din2_re.value = 0
    dut.din2_im.value = 0
    dut.din_valid.value =0
    dut.new_acc.value =0
    
    await ClockCycles(dut.clk, 5)


async def write_data(dut, generator, acc_cycles, iters, din_width, din_pt,cont, burst_len):
    """ Generator   :   class that generate the inputs
        acc_cycles  :   is the number of cycles between two new acc signal
        cont        :   to have a continous stream, otherwise is a burst
        burst_len   :   if the data is not continous, the burst lenght of data,
                        followed by a 
    """
    count = 0
    dut.new_acc.value = 1
    await ClockCycles(dut.clk,1)
    for i in range(iters):
        dat0, dat1 = generator.get_sample()
        dat0, dat1 = two_comp_pack(np.array([dat0, dat1]), din_width, din_pt)
        dut.din1_re.value = dat0.real
        dut.din1_im.value = dat0.imag
        dut.din2_re.value = dat1.real
        dut.din2_re.value = dat1.imag
        dut.din_valid.value = 1;
        count +=1
        await ClockCycles(dut.clk,1)
        if(count == (acc_cycles)):
            count = 0
            dut.new_acc.value = 1
        else:
            dut.new_acc.value = 0

async def read_data(dut, dout_width, dout_pt, iters):
    count =0 
    while(count<iters):
        valid = int(dut.dout_valid.value)
        if(valid):
            r11 = int(dut.r11.value)
            r22 = int(dut.r22.value)
            r12_re = int(dut.r12_re.value)
            r12_im = int(dut.r12_im.value)
            r11, r22, r12_im, r12_re = two_comp_pack(np.array([r11,r22,r12_im, r12_re]),
                dout_width, dout_pt)
            



    
    
    


        


         

            
            

            







