import cocotb, sys
from scipy.fftpack import fft
from scipy.stats import circmean
sys.path.append('../../../../')
import numpy as np
import matplotlib.pyplot as plt
from itertools import cycle
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from two_comp import two_comp_pack, two_comp_unpack


###
### Author: Sebastian Jorquera
###


@cocotb.test()
async def point_doa_no_la(dut, iters=512, acc_len=50, vec_len=64,bands=4,
        din_width=16, din_pt=14, dout_width=20, dout_pt=10, corr_shift=0,
        corr_width=16, corr_pt=8, corr_thresh=1,cont=1, burst_len=10, 
        thresh=0.2, collect_phases=1, print_all=0):
    ##hyper params for the data generation

    freqs = [3, 18, 33, 54]
    phases = [-10,-56, -75, -33]
    amps = [0.01, 0.02 ,0.2, 0.02]
    noise_std = 10**-3

    iters_doa = 65*2*2*2
    phases_plot = 30         #+- plot phases

    thresh = thresh*acc_len
    
    ##
    clk = Clock(dut.clk, 10, units='ns')
    cocotb.fork(clk.start())
    np.random.seed(29)

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

    ##generate input data
    generator = gen_data(dft_len=vec_len,iters=iters*acc_len, freqs=freqs, phases=phases, 
            amplitude=amps, noise_std=noise_std)

    dat0, dat1 = (generator.antenna0, generator.antenna1)
    norm = np.max(np.array([dat0.real, dat0.imag, dat1.real, dat1.imag]))
    dat0 = dat0/norm
    dat1 = dat1/norm
   
    #plot the input spectra
    fig=plt.figure();   ax1 = fig.add_subplot(121); ax2=fig.add_subplot(122)
    ax1.plot(20*np.log10(np.abs(dat0[0,:])))
    ax2.plot(20*np.log10(np.abs(dat1[0,:])))
    ax1.set_title('Antenna 0')
    ax2.set_title('Antenna 1')
    ax1.grid()
    ax2.grid()
    colors = ['b','g','r','c','m','y','k']
    for i in range(bands):
        y = np.linspace(0, -80)
        ax1.fill_betweenx(y, vec_len//bands*i, vec_len//bands*(i+1), facecolor=colors[i],
                alpha=0.2)
        ax2.fill_betweenx(y, vec_len//bands*i, vec_len//bands*(i+1), facecolor=colors[i],
                alpha=0.2)
    plt.savefig('in_spect.png')
    plt.close()

    ##gold results
    r11,r22,r12 = uesprit_matrix(dat0.T, dat1.T, acc_len)

    r11 = np.sum(r11.reshape([bands, vec_len//bands, iters]), axis=1)
    r22 = np.sum(r22.reshape([bands, vec_len//bands, iters]), axis=1)
    r12 = np.sum(r12.reshape([bands, vec_len//bands, iters]), axis=1)
    
    r11 = r11/2.**corr_shift
    r12 = r12/2.**corr_shift
    r22 = r22/2.**corr_shift

    gold_corr = [r11.T.flatten(),r22.T.flatten(), r12.T.flatten()]

    l1,l2,eig1,eig2,frac = uesprit_eigen(r11.T.flatten(),r22.T.flatten(),r12.T.flatten())
    gold = [l1,l2,eig1,eig2,frac]

    ##convert data into binary
    din0_re = two_comp_pack(dat0.flatten().real, din_width, din_pt)
    din0_im = two_comp_pack(dat0.flatten().imag, din_width, din_pt)
    din1_re = two_comp_pack(dat1.flatten().real, din_width, din_pt)
    din1_im = two_comp_pack(dat1.flatten().imag, din_width, din_pt)

    data = [din0_re+1j*din0_im, din1_re+1j*din1_im]
    
    ##like we subsample in the frequencies
    freq = np.array(freqs)//(vec_len/4)
    
    
    ##start simulation

    cocotb.fork(read_data(dut, gold, bands, dout_width, dout_pt, freq,
                thresh, print_all=print_all))
    if(collect_phases): 
        cocotb.fork(write_data(dut,data, acc_len, vec_len//bands, cont, burst_len))
        gold_phases,rtl_phases = await collect_doa(dut, gold,vec_len, dout_width, dout_pt, freq.astype(int), iters_doa)
        fig = plt.figure()
        ax_shape = get_fig_shape(len(freq))
         
        for i in range(len(freq)):
            print('band %i'%freq[i])
            ax = fig.add_subplot(ax_shape[0],ax_shape[1],i+1)
            ax_lim = [-phases[i]-phases_plot, -phases[i]+phases_plot]
            ax.set_title('Band %i  doa: %.3f' %(freq[i], -phases[i]))
            ax.plot(gold_phases[str(int(freq[i]))], colors[0]+'x', label='python doa')
            ax.plot(rtl_phases[str(int(freq[i]))], colors[1]+'.', label='rtl doa')
            rtl_median = np.median(rtl_phases[str(int(freq[i]))])
            gold_median = np.median(gold_phases[str(int(freq[i]))])
            #gold_mean = np.mean(gold_phases[str(int(freq[i]))])
            #rtl_mean = np.mean(rtl_phases[str(int(freq[i]))])
            gold_mean = np.rad2deg(circmean(np.deg2rad(gold_phases[str(int(freq[i]))])))
            rtl_mean = np.rad2deg(circmean(np.deg2rad(rtl_phases[str(int(freq[i]))])))
            print('Right answer %.4f' %(-phases[i]))
            print('python median: %.4f \t rtl median: %.4f '%(gold_median, rtl_median))
            print('python mean: %.4f \t rtl mean: %.4f \n'%(gold_mean, rtl_mean))
            plt.axhline(rtl_median,0, 
                    len(rtl_phases[str(int(freq[i]))]), color=colors[2],
                    linestyle='--', label='rtl median')
            plt.axhline(gold_median,0, 
                    len(rtl_phases[str(int(freq[i]))]), color=colors[3],
                    linestyle='-.', label='python median')
            ax.set_ylim(ax_lim)
            ax.grid()
        line_label = [ax.get_legend_handles_labels()]
        lines, labels = [sum(lol,[]) for lol in zip(*line_label)]
        plt.tight_layout()
        fig.legend(lines, labels, bbox_to_anchor=(1.04,0))
        plt.savefig('doa.png',bbox_inches = "tight")
        plt.close()
    else:
        await (write_data(dut,data, acc_len, vec_len//bands, cont, burst_len))
       

def get_fig_shape(n_data):
    if(n_data<3):
        return (1,n_data)
    elif(n_data<5):
        return (2,2)
    elif(n_data<7):
        return (2,3)
    elif(n_data<10):
        return (3,3)
    else:
        return (4,4)


    
    
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


async def read_data(dut, gold, vec_len, dout_width, dout_pt, freqs, thresh, print_all=0,
        collect_doa=None):
    """ gold        :   floating point values
        vec_len     :   number of fft channels
        dout_width  :   output bitwidth
        dout_pt     :   output binary point
        freqs       :   list with the frequencies of the soi
        thresh      :   threshold for determine an error (gold-rtl_values)
        print_all   :   print all valid output (even if there is not signal in that band)
        collect_doa :   to collect the rtl and gold DoA, put a global variable  
                        to be able to get the value if you want to kill the process
    """
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
            
            if(np.isin((count%vec_len), freqs).any() or print_all):
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

            
async def collect_doa(dut, gold,vec_len, dout_width, dout_pt, bands, iters):
    count = 0
    while(count < vec_len):
        valid = int(dut.dout_valid.value)
        if(valid):
            count += 1
        await ClockCycles(dut.clk, 1)
    count =0
    gold_out = {}
    rtl_out = {}
    for band in bands:
        band_dout = {str(band):[]}
        gold_out.update(band_dout)
        band_dout = {str(band):[]}
        rtl_out.update(band_dout)
    write_count = 0
    while(write_count < iters): 
        valid = int(dut.dout_valid.value)
        error = int(dut.dout_error.value)
        if(error):
            count += 1
            pass
        band_out = int(dut.band_out.value)
        if(valid):
            e1 = int(dut.eigen1_y.value)
            ex = int(dut.eigen_x.value)
            outs = np.array([e1,ex])
            outs = two_comp_unpack(outs, dout_width, dout_pt)
            gold_phase = np.rad2deg(np.arctan2(gold[2][count].real, gold[4][count].real)*2)
            rtl_phase = np.rad2deg(np.arctan2(float(outs[0]), float(outs[1]))*2)
            if(np.isin((band_out), bands).any()):
                gold_out[str(band_out)].append(gold_phase)
                rtl_out[str(band_out)].append(rtl_phase)
                write_count +=1 
            count +=1
        await ClockCycles(dut.clk, 1)
    return [gold_out, rtl_out]


###
###The task below are to debug the internal signals
###


async def check_correlator_output(dut, gold, vec_len, dout_width, dout_pt, thresh):
    count =0
    ##skip the first output because is garbage
    while(count < vec_len):
        valid = int(dut.band_vector_doa_inst.la_in_valid.value)
        if(valid):
            count += 1
        await ClockCycles(dut.clk, 1)
    count = 0
    while(count < len(gold[0])):
        valid = int(dut.band_vector_doa_inst.la_in_valid.value)
        if(valid):
            r11 = int(dut.band_vector_doa_inst.r11_data.value)
            r22 = int(dut.band_vector_doa_inst.r22_data.value)
            r12 = int(dut.band_vector_doa_inst.r12_data.value)
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
    return collect
        
async def check_sqrt_output(dut, gold, vec_len, dout_width, dout_pt, thresh):
    #TODO
    return 1


    
