import numpy as np


samples = 128
streams = 8


data = np.sin(2*np.pi/128*10*np.arange(samples))
gold = np.fft.fft(data)

data_streams = data.reshape((-1, streams))

