import numpy as np
import matplotlib.pyplot as plt
import h5py
from scipy.stats import circstd

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



f = h5py.File('arte_tone.hdf5','r')

acc = 16
bands = 32

adc0 = np.array(f['adc0']) 
adc1 = np.array(f['adc1']) 
adc2 = np.array(f['adc2']) 

#x axis
#u-esprit way
#this takes all the channels
r11,r22,r12 = uesprit_matrix(adc0/2.**15, adc1/2.**15, acc)
l1,l2,e1,e2,ef = uesprit_eigen(r11,r22,r12)
phases = np.arctan2(e1.real, ef.real)


fig, axes = plt.subplots(3,1)
fig.suptitle('X axis')
axes[0].set_title('$\lambda_{1}$')
axes[1].set_title('$\lambda_{2}$')
axes[2].set_title('$\lambda_{1}-\lambda_{2}$')
axes[0].plot(l1[:,10].real)
axes[1].plot(l2[:,10].real)
axes[2].plot(l1[:,10].real-l2[:,10].real)
axes[0].grid()
axes[1].grid()
axes[2].grid()
fig.set_tight_layout(1)


fig, axes = plt.subplots(1,1)
axes.plot(np.rad2deg(phases[:,0]))
axes.plot(np.rad2deg(phases[:,1]))
axes.plot(np.rad2deg(phases[:,2]))
axes.grid()
fig.set_tight_layout(1)

#FFT way
corr = adc0*np.conj(adc1)
corr_acc = np.sum(corr.reshape([-1, 512/acc, acc]), axis=2)
corr_phase = np.angle(corr_acc)

fig, axes= plt.subplots(1,1)
axes.plot(np.rad2deg(corr_phase[:, 0]))
axes.plot(np.rad2deg(corr_phase[:, 1]))
axes.plot(np.rad2deg(corr_phase[:, 2]))
axes.set_title('FFT way')
axes.grid()
fig.set_tight_layout(1)

##Here we check the variability of the 
corr_std = np.rad2deg(circstd(corr_phase, axis=1))
esprit_std = np.rad2deg(circstd(phases, axis=1))


fig, axes = plt.subplots(3,1)
axes[0].plot(corr_std)
axes[0].set_title('SD correlator way')
axes[0].grid()
axes[0].set_ylabel('deg')
axes[1].plot(esprit_std)
axes[1].set_title('SD esprit way')
axes[1].grid()
axes[1].set_ylabel('deg')
axes[2].plot(20*np.log10(np.mean(np.abs(adc0), axis=1)))
axes[2].set_title('Antenna 0 spectrum')
axes[2].grid()
axes[2].set_ylabel('deg')
fig.set_tight_layout(1)

plt.show()

##
## band uesprit 

r11 = np.sum(r11.reshape([bands, 2048//bands, -1]), axis=1)
r12 = np.sum(r12.reshape([bands, 2048//bands, -1]), axis=1)
r22 = np.sum(r22.reshape([bands, 2048//bands, -1]), axis=1)


l1_b,l2_b,e1_b,e2_b,ef_b = uesprit_eigen(r11,r22,r12)
band_phases = np.arctan2(e1_b.real, ef_b.real)

