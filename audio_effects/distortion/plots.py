import matplotlib.pyplot as plt
import wave, struct
import numpy as np
from scipy.fftpack import fft

din = wave.open('440Hz.wav')
dout = wave.open('out.wav')
fs = din.getframerate()/10.**3

nframes = 2**10

aux1 = din.readframes(nframes)
dat_in = struct.unpack(str(nframes)+'h', aux1)
aux1 = dout.readframes(nframes)
dat_out = struct.unpack(str(nframes)+'h',aux1)


plt.plot(dat_in, '*-')
plt.plot(dat_out,'*-')

fig = plt.figure()
ax1 = fig.add_subplot(121)
ax2 = fig.add_subplot(122)
spec_in = fft(dat_in)
spec_out = fft(dat_out)
freq = np.linspace(0,fs,len(spec_in))

ax1.plot(freq[:len(spec_in)/2], 20*np.log10(np.abs(spec_in[:len(spec_in)/2])+1))
ax2.plot(freq[:len(spec_in)/2], 20*np.log10(np.abs(spec_out[:len(spec_in)/2])+1))

ax1.grid()
ax2.grid()

plt.show()

