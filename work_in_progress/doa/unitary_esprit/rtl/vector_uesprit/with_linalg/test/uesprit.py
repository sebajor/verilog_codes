import numpy as np
import ipdb

def add_noise(adc_data, snr):
    size = adc_data.shape
    linear_snr = 10**(snr/10.)
    pow_in = np.mean(adc_data*np.conj(adc_data),axis=1)
    sigma = np.sqrt(pow_in.real/linear_snr)
    noise = np.random.normal(0, 8*sigma[0],size)+1j*np.random.normal(0, 8*sigma[0],size)
    output = adc_data+noise
    return output


def single_source(x_space=0.005, freq=10, phase=30, length=64, dft_len=64):
    n_antenna = 2
    t = np.arange(length)
    sig = np.exp(1j*2*np.pi*freq*t/dft_len)#+phase)
    #ipdb.set_trace()
    element = np.arange(n_antenna)
    doa_ang = np.deg2rad(phase)
    phase_steer = 2*np.pi*x_space*freq*np.sin(doa_ang)
    #print("phase steer: %.4f"%(phase_steer%(2*np.pi)))
    steer = np.exp(1j*element*phase_steer)
    output = np.zeros([n_antenna, length], dtype=complex)
    for i in range(n_antenna):
        output[i,:] = steer[i]*sig
    return output


def multi_source(freqs=[10,40], phases=[10, 40], x_space=0.005,length=64, dft_len=64):
    out = np.zeros([2,length])
    for freq, phase in zip(freqs, phases):
        vals = single_source(x_space=x_space, freq=freq, phase=phase, dft_len=dft_len, length=length)
        out = out+vals
    return out



def uesprit_matrix(data):
    """data: [2, length]
    """
    #ipdb.set_trace()
    dat0 = data[0]
    dat1 = data[1]
    y1 = dat0+dat1#data[0,:]+data[1,:]
    y2 = dat0-dat1#data[0,:]-data[1,:]
    y2 = y2.imag-1j*y2.real

    R11 = np.sum(y1*np.conj(y1), axis=0)
    R22 = np.sum(y2*np.conj(y2), axis=0)
    R12 = np.sum(y1*np.conj(y2), axis=0)
    return [R11.real, R12, R22.real]


def uesprit_la(r11,r12,r22):
    #ipdb.set_trace()
    r21 = r12
    lamb1 = (r11+r22+np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    lamb2 = (r11+r22-np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    eig1 = -(r11-lamb1)
    eig2 = -(r11-lamb2)
    return [lamb1, lamb2, eig1, eig2, r12]
"""
def uesprit_la(r11,r12,r22, x_space, freq):
    r21 = r12
    lamb1 = (r11+r22+np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    lamb2 = (r11+r22-np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    mu1 = 2*np.arctan((r11-lamb1)/r12)
    mu2 = 2*np.arctan((r11-lamb2)/r12)
    mu = mu1/(2*np.pi*x_space*freq)
    doa = np.rad2deg(np.arcsin(mu))
    return [doa, mu, lamb1, lamb2]
"""




