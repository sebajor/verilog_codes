import numpy as np
import matplotlib.pyplot as plt
from scipy.fftpack import fft

def msdft(data, N, k):
    n = np.arange(N)
    twidd = np.exp(-1j*2*np.pi*k*n/N)
    delay_line = np.zeros(N+1, dtype=complex)   #N+1 because we need a N delay
    resonator =0
    out = np.zeros(len(data), dtype=complex)
    for i in range(len(data)):
        delay_line = np.roll(delay_line,1)
        delay_line[0] = data[i]
        comb = data[i]-delay_line[-1]
        mult = twidd[i%N]*comb
        resonator = resonator+mult
        out[i] = resonator
    return out


def msdft_correlator(data1, data2, N, k):
    msdft1 = msdft(data1,N,k)
    msdft2 = msdft(data2,N,k)
    pow1 = msdft1**2
    pow2 = msdft2**2
    corr = msdft1*np.conj(msdft2)
    return [pow1, pow2, corr]


def add_noise(adc_data, snr):
    size = adc_data.shape
    linear_snr = 10**(snr/10.)
    pow_in = np.mean(adc_data*np.conj(adc_data))
    sigma = np.sqrt(pow_in.real/linear_snr)
    noise = np.random.normal(0, 8*sigma,size)
    output = adc_data+noise
    return output


def corr_test(length, N, k, amp1, phase1, amp2, phase2, snr1, snr2):
    t = np.arange(length)
    dat1 = amp1*np.sin(2*np.pi*k*t/N+np.deg2rad(phase1))
    dat2 = amp2*np.sin(2*np.pi*k*t/N+np.deg2rad(phase2))
    dat1 = add_noise(dat1, snr1)
    dat2 = add_noise(dat2, snr2)
    pow1, pow2, corr = msdft_correlator(dat1,dat2,N,k)
    pow_db = 10*(np.log10(np.abs(pow1))-np.log10(np.abs(pow2)))
    ang_deg = np.rad2deg(np.angle(corr))
    gold_pow = 10*(np.log10(amp1**2/2.)-np.log10(amp2**2/2.))
    gold_ang = phase1-phase2
    return [pow_db, ang_deg, gold_pow, gold_ang]

