import sim_data, ipdb
import numpy as np
import matplotlib.pyplot as plt
from scipy.fftpack import fft


def test1(x_space=0.001, freq=450, ang=55, snr=40, length=1024):
    n_antennas = 2      #number of antennas (in this script we only play with one)
    clean_sig = sim_data.adc_data(n_antennas,x_space,freq,ang,length)
    data = sim_data.add_noise(clean_sig, snr)
    data = data/np.max(np.abs(data))
    doa, mu, lamb, cov_mat = sim_data.u_esprit_2ant(data, x_space=x_space, freq=freq)
    print("actual: %.4f \t predicted: %.4f"%(ang, doa))
    return [doa, mu, lamb, cov_mat]


def test2(x_space=0.001, freq=450, ang=55,snr=60,length=1024, fft_length=1024):
    n_antennas = 2
    data = sim_data.fft_data(n_antenna=n_antennas, x_space=x_space, freq=freq, ang=ang, length=length, fft_length=fft_length, snr=snr)
    reduced_data = data[:,:,freq]
    #ipdb.set_trace()
    reduced_data = reduced_data/np.max(reduced_data.real) 
    doa, mu, lamb, cov_mat = sim_data.u_esprit_2ant(reduced_data, x_space=x_space, freq=freq)
    print("actual: %.4f \t predicted: %.4f"%(ang, doa))
    return [doa, mu, lamb, cov_mat]



def test3(x_space=0.001, freq1=450, ang1=55, freq2=100, ang2=80, snr=60,length=1024, fft_length=1024):
    ##multiple signals
    n_antennas = 2      #number of antennas (in this script we only play with one)
    clean_sig = sim_data.adc_data(n_antennas,x_space,freq1,ang1,length*fft_length)
    clean_sig2 = sim_data.adc_data(n_antennas,x_space,freq2,ang2,length*fft_length) 
    data = sim_data.add_noise(clean_sig+clean_sig2, snr)
    data = data/np.max(np.abs(data))
    doa1, mu1, lamb1, cov_mat1 = sim_data.u_esprit_2ant(data, x_space=x_space, freq=freq1)
    doa2, mu2, lamb2, cov_mat2 = sim_data.u_esprit_2ant(data, x_space=x_space, freq=freq2)
    print("typical u esprit")
    print("actual1: %.4f \t predicted1: %.4f"%(ang1, doa1))
    print("actual2: %.4f \t predicted2: %.4f"%(ang2, doa2))
    
    ##dft version
    fft_data = np.zeros([n_antennas, length, fft_length], dtype=complex)
    for i in range(n_antennas):
        fft_data[i,:,:] = fft((data[i,:].reshape([length, fft_length])).real, axis=0).T
    reduced_data1 = fft_data[:,:,freq1]
    reduced_data1 = reduced_data1/np.max(reduced_data1)
    reduced_data2 = fft_data[:,:,freq2]
    reduced_data2 = reduced_data2/np.max(reduced_data2)
    doa1, mu1, lamb1, cov_mat1 = sim_data.u_esprit_2ant(reduced_data1, x_space=x_space, freq=freq1)
    doa2, mu2, lamb2, cov_mat2 = sim_data.u_esprit_2ant(reduced_data2, x_space=x_space, freq=freq2)
    print("fft u esprit")
    print("actual1: %.4f \t predicted1: %.4f"%(ang1, doa1))
    print("actual2: %.4f \t predicted2: %.4f"%(ang2, doa2))




