import numpy as np
from scipy.fftpack import fft
import itertools

def add_noise(signal, snr):
    """The function is not that good even if we target the actual noise power
    the result is different :( .. check the actual snr of the signal
    """
    signal_pow = 20*np.log10(np.sum(signal*np.conj(signal), axis=0).real)
    noise_pow = signal_pow-snr
    noise_lin = 10**(noise_pow/20.) ##check!!
    noise = (np.random.random(size=signal.shape) +1j*np.random.random(size=signal.shape)
            )*np.sqrt(noise_lin)
    actual_snr = signal_pow-np.mean(20*np.log10(np.abs(fft(noise))))
    return signal+noise, noise, actual_snr


def single_source(x_space=0.005, freq=10, phase=30, length=64, dft_len=64):
    n_antenna = 2
    t = np.arange(length)
    sig = np.exp(1j*(2*np.pi*freq*t/dft_len+np.random.random()*np.pi/4))
    element = np.arange(n_antenna)
    doa_ang = np.deg2rad(phase)
    phase_steer = 2*np.pi*x_space*freq*np.sin(doa_ang)
    steer = np.exp(1j*element*phase_steer)
    output = np.zeros([n_antenna, length], dtype=complex)
    for i in range(n_antenna):
        output[i,:] = steer[i]*sig
    return output


def multi_source(freqs=[10,40], phases=[10,40], xspace=0.005, length=64, dft_len=64):
    out = np.zeros([2, length],dtype=complex)
    for freqs, phases in zip(freqs, phases):
        vals = single_source(x_space=x_space, freq=freq, phase=phase, 
                    length=length, dft_len=dft_len)
        out = out+vals
    return out


def uesprit_matrix(data):
    """
        data:   [2, length] 
                the axis 0 is the antenna index
    """
    y1 = data[0,:]+data[1,:]
    y2 = data[0,:]-data[1,:]
    y2 = y2.imag-1j*y2.real

    R11 = np.sum(y1*np.conj(y1), axis=0)
    R22 = np.sum(y2*np.conj(y2), axis=0)
    R12 = np.sum(y1*np.conj(y2), axis=0)
    return [R11.real, R12, R22.real]


def uesprit_la(r11,r12,r22, x_space, freq):
    ipdb.set_trace()
    r21 = r12
    lamb1 = (r11+r22+np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    lamb2 = (r11+r22-np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    mu1 = 2*np.arctan((r11-lamb1)/r12)
    mu2 = 2*np.arctan((r11-lamb2)/r12)
    mu = mu1/(2*np.pi*x_space*freq)
    doa = np.rad2deg(np.arcsin(mu))
    return [mu1, mu2, lamb1, lamb2, doa]
    #return [doa, mu, lamb1, lamb2]
    



