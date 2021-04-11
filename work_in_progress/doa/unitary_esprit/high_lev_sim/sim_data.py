import numpy as np
import ipdb 
from scipy.fftpack import fft

def adc_data(n_antenna=2, x_space=0.005, freq=10, ang=30, length=1024):
    t = np.arange(length)
    phase = np.random.random()*np.pi
    sig = np.exp(1j*2*np.pi*freq*t/length+phase)
    element = np.arange(n_antenna)
    doa_ang = np.deg2rad(ang)
    phase_steer = 2*np.pi*x_space*freq*np.sin(doa_ang)
    print("phase steer: %.4f"%(phase_steer%(2*np.pi)))
    steer = np.exp(1j*element*phase_steer)
    output = np.zeros([n_antenna, length], dtype=complex)
    for i in range(n_antenna):
        output[i,:] = steer[i]*sig
    return output

def add_noise(adc_data, snr):
    size = adc_data.shape
    linear_snr = 10**(snr/10.)
    pow_in = np.mean(adc_data*np.conj(adc_data),axis=1)
    sigma = np.sqrt(pow_in.real/linear_snr)
    noise = np.random.normal(0, 8*sigma[0],size)+1j*np.random.normal(0, 8*sigma[0],size)
    output = adc_data+noise
    return output
    """
    size = adc_data.shape
    pow_in = 10*np.log10(np.sum(adc_data*np.conj(adc_data), axis=1))
    noise_db = pow_in.real-snr
    noise_watt = 10**(noise_db/10.)
    noise_watt = np.mean(noise_watt)
    noise = np.random.normal(0, np.sqrt(noise_watt), size)+1j*np.random.normal(0, np.sqrt(noise_watt), size)
    output = adc_data+noise
    return output
    """

def fft_data(n_antenna=2, x_space=0.005, freq=10, ang=30, length=1024, fft_length=1024, snr=50):
    #ipdb.set_trace()
    adc_vals = adc_data(n_antenna=n_antenna, x_space=x_space, freq=freq, ang=ang, length=length*fft_length)
    adc_vals = add_noise(adc_vals, snr)
    adc_vals = adc_vals.real
    out = np.zeros([n_antenna, length, fft_length], dtype=complex)
    for i in range(n_antenna):
        out[i,:,:] = fft(adc_vals[i,:].reshape([length, fft_length]),axis=0).T
    return out
    #spect_data = fft(adc_vals, axis=1)
    #return spect_data



def u_esprit_2ant(data ,x_space=0.005, freq=10):
    """ data: complex normalized, axis0: antenna number, axis1:data
    """
    n_antenna = data.shape[0]
    length = data.shape[1]
    #symetric and antisymetric matrix mult (rotations)
    y1 = data[0,:]+data[1,:]
    y2 = data[0,:]-data[1,:]
    y2 = y2.imag-1j*y2.real

    #covariance matrix
    R11 = np.mean(y1*np.conj(y1))
    R12 = np.mean(y1*np.conj(y2))
    R22 = np.mean(y2*np.conj(y2))
    R21 = np.conj(R12)
    #keep it real
    r11 = R11.real
    r12 = R12.real
    r21 = R12.real
    r22 = R22.real

    #eigenvalues (luckily is just a cuadratic form)
    #math:
    #(r11-val)(r22-val)-r12*r21 = 0
    # val**2-(r11+r22)val+(r11*r22)-r12*r21 = 0
    ##r11+r22+sqrt((r11-r22)**2-4*(r12**2))

    lamb1 = (r11+r22+np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2
    lamb2 = (r11+r22-np.sqrt((r11+r22)**2-4*(r11*r22-r12*r21)))/2

    #eigen vector
    #math:
    # r11*x+r12*y = lamb*x    ---> (r11-lamb)x = -r12*y
    # r21*x+r22*y = lamb*y    ---> (r22-lamb)y = -r12*x
    #---> ((r11-lamb)/r12)x = -y; thats our eigenvector 


    mu1 = 2*np.arctan((r11-lamb1)/r12)
    mu2 = 2*np.arctan((r11-lamb2)/r12)
    print("esprit steer: %.4f" %mu1) 
    mu = mu1/(2*np.pi*x_space*freq)
    doa = np.rad2deg(np.arcsin(mu))
    return [doa, mu, lamb1, [[R11, R12],[R21, R22]]]

