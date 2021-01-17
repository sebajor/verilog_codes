import numpy as np
import matplotlib.pyplot as plt
import struct
from scipy.fftpack import fft

f = file('out', 'rb')
dat = struct.unpack('>128i',f.read(128*4))
dat = struct.unpack('>128i',f.read(128*4))

plt.figure()
plt.plot(dat)
spec = fft(dat)
plt.figure()
plt.plot(20*np.log10(np.abs(spec)+1))
plt.show()
