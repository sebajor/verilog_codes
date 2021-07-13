import numpy as np
import struct, optparse
from calandigital import float2fixed
import matplotlib.pyplot as plt
import ipdb

def twidd_gen(din_width=16, din_pt=14 ,k=50, dft_size=128, filename="twidd_init.hex", plot=0):
    dtypes=['b','h','i','q']
    ind = int(din_width/8)-1
    dt = dtypes[ind]
    f = open(filename, 'w')
    n = np.arange(dft_size)
    data = np.exp(-1j*2*np.pi*k/dft_size*n)
    re = data.real
    im = data.imag
    twidd_data = np.empty(2*dft_size, dtype=int)
    re_data = float2fixed(re, nbits=din_width,binpt=din_pt)
    im_data = float2fixed(im, nbits=din_width,binpt=din_pt)
    if(plot):
        plt.plot(re_data, label='re')
        plt.plot(im_data, label='im')
        plt.title("Bin n: "+str(k))
        plt.grid()
        plt.legend()
        plt.show()
    for i in range(dft_size):
        twidd = np.array([re_data.astype(int), im_data.astype(int)])
        hex_twidd = struct.pack('>2'+dt, *(twidd[:,i]))
        f.write(hex_twidd.encode('hex'))
        #hex_re = struct.pack('>'+dt, int(re_data[i]))
        #hex_im = struct.pack('>'+dt, int(im_data[i]))
        #f.write(hex_re.encode('hex'))
        #f.write(hex_im.encode('hex'))
        f.write('\n')
    f.close()



parser = optparse.OptionParser()

parser.add_option('-i', '--din_width',
                    dest='din_width',
                    type='int',
                    help='input bitwidth, must be power of two')
parser.add_option('-t', '--din_pt',
                    dest='din_pt',
                    type='int',
                    help='din bit point location')
parser.add_option('-k', '--twidd_num',
                    dest='twidd_num',
                    type='int',
                    help='twiddle factor number')
parser.add_option('-n', '--dft_size',
                    dest='dft_size',
                    type='int',
                    help='dft size')
parser.add_option('-f', '--filename',
                    dest='filename',
                    type='string',
                    help='filename where is stored the values')
parser.add_option('-p','--plot',
                    dest='plot',
                    type='int',
                    help='plot the result')

(opt, args) = parser.parse_args()
twidd_gen(opt.din_width, opt.din_pt, opt.twidd_num, opt.dft_size,
        opt.filename, opt.plot)

