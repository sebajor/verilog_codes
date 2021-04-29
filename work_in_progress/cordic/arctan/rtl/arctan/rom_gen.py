import numpy as np
import matplotlib.pyplot as plt
import struct, optparse

def arctan_gen(din_width, dout_width, filename='atan_rom.hex'):
    dtypes=['b','h','i','q']
    ind = int(dout_width/8)-1
    dt = dtypes[ind]
    f = open(filename, 'w')
    for i in range(din_width):
        data = np.arctan(2.**(-i))/np.pi
        out = int(data*2**(dout_width-1))
        data_hex = struct.pack('>'+dt, out)
        f.write(data_hex.encode('hex'))
        f.write('\n')
    f.close()



if __name__ == '__main__':
    arctan_gen(16, 16)
