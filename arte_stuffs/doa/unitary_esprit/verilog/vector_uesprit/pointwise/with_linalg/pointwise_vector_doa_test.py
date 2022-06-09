import cocotb, sys
from scipy.fftpack import fft
sys.path.append('../../../')
import numpy as np
from itertools import cycle
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from two_comp import two_comp_pack, two_comp_unpack
import matplotlib.pyplot as plt


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

 
def uesprit_eigen(r11,r22,r12):
    r21 = r12
    lamb1 = (r11+r22+np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    lamb2 = (r11+r22-np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    eigvec1 = -(r11-lamb1)
    eigvec2 = -(r11-lamb2)
    eigfrac = r12
    return [lamb1, lamb2,eigvec1,eigvec2,eigfrac]


@cocotb.test()
async def pointwise_vector_doa_test(dut, iters=10, acc_len=10, vec_len=64,din_width=16, din_pt=14, 
        dout_width=16, dout_pt=10, corr_shift=4,cont=1, burst_len=10, thresh=0.5):
    ##hyper params for the data generation
    freqs = [2, 20, 33, 50]
    phases = [-123, 100, 40, -70]
    amps = [0.1, 0.5, 0.2, 0.8]
    
    ##
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    
    #setup the dut 
    dut.din1_re.value = 0
    dut.din1_im.value = 0
    dut.din2_re.value = 0
    dut.din2_im.value = 0
    dut.din_valid.value =0
    dut.new_acc.value =0
    
    await ClockCycles(dut.clk, 5)

    generator = gen_data(dft_len=vec_len,iters=iters*acc_len, freqs=freqs, phases=phases, 
            amplitude=amps, noise_std=10**-3)

    dat0, dat1 = (generator.antenna0, generator.antenna1)
    norm = np.max(np.array([dat0.real, dat0.imag, dat1.real, dat1.imag]))
    dat0 = dat0/norm
    dat1 = dat1/norm
    
    fig=plt.figure();   ax1 = fig.add_subplot(121); ax2=fig.add_subplot(122)
    ax1.plot(20*np.log10(np.abs(dat0[0,:])))
    ax2.plot(20*np.log10(np.abs(dat1[0,:])))
    plt.savefig('in_spect.png')
    plt.close()


    r11,r22,r12 = uesprit_matrix(dat0.T, dat1.T, acc_len)
    r11 = r11/2.**corr_shift
    r22 = r22/2.**corr_shift
    r12 = r12/2.**corr_shift

    l1,l2,e1,e2,e_frac = uesprit_eigen(r11.T.flatten(), r22.T.flatten(), r12.T.flatten())
    gold = [l1,l2,e1,e2,e_frac]
    
    #gold = [r11.T.flatten(), r22.T.flatten(), r12.T.flatten()]

    din0_re = two_comp_pack(dat0.flatten().real, din_width, din_pt)
    din0_im = two_comp_pack(dat0.flatten().imag, din_width, din_pt)
    din1_re = two_comp_pack(dat1.flatten().real, din_width, din_pt)
    din1_im = two_comp_pack(dat1.flatten().imag, din_width, din_pt)

    data = [din0_re+1j*din0_im, din1_re+1j*din1_im]

    cocotb.fork(read_data(dut, gold, vec_len, dout_width, dout_pt,freqs, thresh))
    await write_data(dut,data, acc_len,vec_len, cont, burst_len)
    

async def write_data(dut, data, acc_len,vec_len, cont, burst_len):
    dut.new_acc.value=1
    await ClockCycles(dut.clk, 1)
    dut.new_acc.value =0
    count = 1
    if(cont):
       for i in range(len(data[0])):
           dut.din_valid.value = 1
           dut.din1_re.value = int(data[0][i].real)
           dut.din1_im.value = int(data[0][i].imag)
           dut.din2_re.value = int(data[1][i].real)
           dut.din2_im.value = int(data[1][i].imag)
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


async def read_data(dut, gold, vec_len, dout_width, dout_pt, freqs, thresh):
    count = 0
    while(count < vec_len):
        valid = int(dut.dout_valid.value)
        if(valid):
            count += 1
        await ClockCycles(dut.clk, 1)
    count = 0
    while(count<len(gold[0])):
        valid = int(dut.dout_valid.value)
        error = int(dut.dout_error.value)
        if(error):
            count += 1
            pass
        if(valid):
            l1 = int(dut.lamb1.value)
            l2 = int(dut.lamb2.value)
            e1 = int(dut.eigen1_y.value)
            e2 = int(dut.eigen2_y.value)
            ex = int(dut.eigen_x.value)
            outs = np.array([l1,l2,e1,e2,ex])
            outs = two_comp_unpack(outs, dout_width, dout_pt)
            
            if(np.isin((count%vec_len), freqs).any()):
                print("%i"%(count%vec_len))
                print("l1 \t gold: %.3f \t rtl: %.3f" %(gold[0][count].real, outs[0]))
                print("l2 \t gold: %.3f \t rtl: %.3f" %(gold[1][count].real, outs[1]))
                print("eig1 \t gold: %.3f \t rtl: %.3f" %(gold[2][count].real, outs[2]))
                print("eig2 \t gold: %.3f \t rtl: %.3f" %(gold[3][count].real, outs[3]))
                print("eig frac \t gold: %.3f \t rtl: %.3f" %(gold[4][count].real, outs[4]))
                gold_phase = np.rad2deg(np.arctan2(gold[2][count].real, gold[4][count].real)*2)
                rtl_phase = np.rad2deg(np.arctan2(float(outs[2]), float(outs[4]))*2)
                print("phase \t gold: %.4f \t rtl: %.4f" %(gold_phase, rtl_phase))

            assert (np.abs(gold[0][count]-outs[0])<thresh), "l1 error"
            assert (np.abs(gold[1][count]-outs[1])<thresh), "l2 error"
            assert (np.abs(gold[2][count]-outs[2])<thresh), "eig1 error"
            assert (np.abs(gold[3][count]-outs[3])<thresh), "eig2 error"
            assert (np.abs(gold[4][count]-outs[4])<thresh), "eig frac error"
            count += 1
        await ClockCycles(dut.clk, 1)
