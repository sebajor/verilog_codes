import numpy as np
import ipdb
from scipy.fftpack import fft

def add_noise(adc_data, snr):
    size = adc_data.shape
    linear_snr = 10**(snr/10.)
    pow_in = np.mean(adc_data*np.conj(adc_data))
    sigma = np.sqrt(pow_in.real/linear_snr)
    noise = np.random.normal(0, 8*sigma,size)
    output = adc_data+noise
    return output


def gen_data(sig_amp=0.5, rfi_amp=0.8,sig_freq=200, rfi_freq=300, length=1024, 
        sig_snr=40, rfi_snr=20):
    t = np.arange(length)
    phase_sig = np.random.random()*np.pi
    phase_sig2 = np.random.random()*np.pi
    phase_rfi = np.random.random()*np.pi
    sig = np.sin(2*np.pi*sig_freq*t/length+phase_sig)
    sig = np.sin(2*np.pi*sig_freq*t/length+phase_sig2)
    rfi = np.sin(2*np.pi*rfi_freq*t/length+phase_rfi)
    sig = rfi_amp*rfi+sig_amp*sig
    sig = add_noise(sig, sig_snr)
    rfi = add_noise(rfi, rfi_snr)
    sig = sig/np.max(sig)
    rfi = rfi/np.max(rfi)
    return [sig, rfi]


