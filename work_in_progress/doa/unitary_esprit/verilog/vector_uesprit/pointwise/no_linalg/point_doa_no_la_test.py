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

        


        


         

            
            

            







