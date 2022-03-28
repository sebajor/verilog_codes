import cocotb, sys
from scipy.fftpack import fft
sys.path.append('../../../../')
import numpy as np
from itertools import cycle
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from two_comp import two_comp_pack, two_comp_unpack


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


def uesprit_matrix(antenna0, antenna1, acc_len):
    """
        antenna:    [vect_len, iters] 
                    and iters = acc_len*n_outputs
    """
    vec_len, iters = antenna0.shape
    y1 = antenna0+antenna1
    y2 = antenna0-antenna1
    y2 = y2.imag -1j*y2.real
    r11 = np.zeros([vec_len, iters//acc_len])
    r22 = np.zeros([vec_len, iters//acc_len])
    r12 = np.zeros([vec_len, iters//acc_len], dtype=complex)
    for i in range(iters//acc_len):
        sample0 = y1[:,i*acc_len:(i+1)*acc_len]
        sample1 = y2[:,i*acc_len:(i+1)*acc_len]
        r11[:, i] = np.sum(sample0*np.conj(sample0), axis=1).real
        r22[:, i] = np.sum(sample1*np.conj(sample1), axis=1).real
        r12[:, i] = np.sum(sample0*np.conj(sample1), axis=1)
    return r11, r22, r12



@cocotb.test()
async def point_doa_no_la(dut, iters=100, acc_len=10, vec_len=64,bands=4,
        din_width=16, din_pt=14, dout_width=32, dout_pt=16, 
        cont=1, burst_len=10, thresh=0.5):
    ##hyper params for the data generation
    freqs = [2, 33]
    phases = [70, 33]
    amps = [0.2, 0.2]
    
    ##
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    np.random.seed(19)

    #setup the dut 
    dut.din1_re0.value = 0
    dut.din1_im0.value = 0
    dut.din2_re0.value = 0
    dut.din2_im0.value = 0

    dut.din1_re1.value = 0
    dut.din1_im1.value = 0
    dut.din2_re1.value = 0
    dut.din2_im1.value = 0

    dut.din1_re2.value = 0
    dut.din1_im2.value = 0
    dut.din2_re2.value = 0
    dut.din2_im2.value = 0

    dut.din1_re3.value = 0
    dut.din1_im3.value = 0
    dut.din2_re3.value = 0
    dut.din2_im3.value = 0

    dut.din_valid.value =0
    dut.new_acc.value =0
    
    await ClockCycles(dut.clk, 5)

    generator = gen_data(dft_len=vec_len,iters=iters*acc_len, freqs=freqs, phases=phases, 
            amplitude=amps, noise_std=10**-3)

    dat0, dat1 = (generator.antenna0, generator.antenna1)
    print(dat0.shape) 
    norm = np.max(np.array([dat0.real, dat0.imag, dat1.real, dat1.imag]))
    dat0 = dat0/norm
    dat1 = dat1/norm

    r11,r22,r12 = uesprit_matrix(dat0.T, dat1.T, acc_len)
    print(r11.shape)
    print(r11[20,0])
    #gold = [r11.T.flatten(), r22.T.flatten(), r12.T.flatten()]
    #r11 = np.sum(r11.T.flatten().reshape([-1, bands]), axis=1)
    #r12 = np.sum(r12.T.flatten().reshape([-1, bands]), axis=1)
    #r22 = np.sum(r22.T.flatten().reshape([-1, bands]), axis=1)
    r11 = np.sum(r11.reshape([bands, vec_len//bands, iters]), axis=1)
    r22 = np.sum(r22.reshape([bands, vec_len//bands, iters]), axis=1)
    r12 = np.sum(r12.reshape([bands, vec_len//bands, iters]), axis=1)
    print(r11.shape)
    gold = [r11.T.flatten(),r22.T.flatten(),r12.T.flatten()]


    din0_re = two_comp_pack(dat0.flatten().real, din_width, din_pt)
    din0_im = two_comp_pack(dat0.flatten().imag, din_width, din_pt)
    din1_re = two_comp_pack(dat1.flatten().real, din_width, din_pt)
    din1_im = two_comp_pack(dat1.flatten().imag, din_width, din_pt)

    data = [din0_re+1j*din0_im, din1_re+1j*din1_im]

    
    cocotb.fork(read_data(dut, gold, bands, dout_width, dout_pt, thresh))
    await write_data(dut,data, acc_len, vec_len//bands, cont, burst_len)
    

async def write_data(dut, data, acc_len,vec_len, cont, burst_len):
    dut.new_acc.value=1
    await ClockCycles(dut.clk, 1)
    dut.new_acc.value =0
    count = 1
    if(cont):
       for i in range(len(data[0])//4):
           dut.din_valid.value = 1
           dut.din1_re0.value = int(data[0][4*i].real)
           dut.din1_im0.value = int(data[0][4*i].imag)
           dut.din2_re0.value = int(data[1][4*i].real)
           dut.din2_im0.value = int(data[1][4*i].imag)

           dut.din1_re1.value = int(data[0][4*i+1].real)
           dut.din1_im1.value = int(data[0][4*i+1].imag)
           dut.din2_re1.value = int(data[1][4*i+1].real)
           dut.din2_im1.value = int(data[1][4*i+1].imag)

           dut.din1_re2.value = int(data[0][4*i+2].real)
           dut.din1_im2.value = int(data[0][4*i+2].imag)
           dut.din2_re2.value = int(data[1][4*i+2].real)
           dut.din2_im2.value = int(data[1][4*i+2].imag)

           dut.din1_re3.value = int(data[0][4*i+3].real)
           dut.din1_im3.value = int(data[0][4*i+3].imag)
           dut.din2_re3.value = int(data[1][4*i+3].real)
           dut.din2_im3.value = int(data[1][4*i+3].imag)

           await ClockCycles(dut.clk,1)
           count +=1
           if(count == (acc_len*vec_len)):
               dut.new_acc.value = 1
               count =0
           else:
               dut.new_acc.value = 0
    else:
        #TODO
        return 1


async def read_data(dut, gold, vec_len, dout_width, dout_pt, thresh):
    count = 0
    while(count < vec_len):
        valid = int(dut.dout_valid.value)
        if(valid):
            count += 1
        await ClockCycles(dut.clk, 1)
    count = 0
    while(count<len(gold[0])):
        valid = int(dut.dout_valid.value)
        if(valid):
            r11 = int(dut.r11.value)
            r22 = int(dut.r22.value)
            r12 = int(dut.r12.value)
            r11,r22,r12 = two_comp_unpack(np.array([r11,r22,r12]),
                    dout_width, dout_pt)
            
            print("%i"%(count%vec_len))
            print("r11    \t rtl:%.3f \t gold:%.3f" %(r11,gold[0][count]))
            print("r22    \t rtl:%.3f \t gold:%.3f" %(r22,gold[1][count]))
            print("r12_re \t rtl:%.3f \t gold:%.3f" %(r12,gold[2][count].real))
            
            assert (np.abs(r11-gold[0][count])<thresh), "Error R11"
            assert (np.abs(r22-gold[1][count])<thresh), "Error R22"
            assert (np.abs(r12-gold[2][count].real)<thresh), "Error R12_re"

            count += 1
        await ClockCycles(dut.clk, 1)
