import numpy as np
import matplotlib.pyplot as plt
import sim_data
from scipy.fftpack import fft


iters=32
length = 256
sig_freq = 30
rfi_freq = 40

n_weigth = length/2


np.random.seed(10)

dat, rfi = sim_data.gen_data(sig_amp=0.5, sig_freq=sig_freq*iters, rfi_freq=rfi_freq*iters,length=length*iters)


#init weights
w = np.random.rand(1,n_weigth)+1j*np.random.rand(1,n_weigth)
w = w[0]
print(w.shape)
dat = dat.reshape([iters, length])
rfi = rfi.reshape([iters, length])

out = np.zeros([iters, length/2], dtype=complex)

for i in range(iters):
    sig_spec = fft(dat[i,:])[:length/2]
    rfi_spec = fft(rfi[i,:])[:length/2]
    est = rfi_spec*w
    out[i,:] = sig_spec-est
    #update weights
    #dw = rfi_spec*np.conj(rfi_spec)*w-sig_spec*np.conj(rfi_spec)
    dw = out[i,:]*np.conj(rfi_spec)#-sig_spec*np.conj(rfi_spec)
    #print(i)
    #print(dw)
    w = w+dw/2.*0.0005  #the learning rate must be (-1/pow_rfi, 1/pow_rfi to converge)

    


fig = plt.figure()
ax1 = fig.add_subplot(131)
ax2 = fig.add_subplot(132)
ax3 = fig.add_subplot(133)

ax1.plot(20*np.log10(np.abs(sig_spec)))
ax1.set_title('Main receiver')
ax1.grid()
ax1.set_ylim(-20, 50)
ax2.plot(20*np.log10(np.abs(rfi_spec)))
ax2.set_title('Reference receiver')
ax2.grid()
ax2.set_ylim(-20, 50)
ax3.plot(20*np.log10(np.abs(out[-1,:])))
ax3.set_title('Mitigated output')
ax3.grid()
ax3.set_ylim(-20, 50)

plt.show()




