import numpy as np
import struct
from scipy.special import expit
import matplotlib.pyplot as plt
import optparse

def sigmoid_gen(sig_size, sig_int, din_size, din_int, filename, plot=0):
    """ like the sigmoid lives in (-1,1) the most logical thing
        is set sig_int=1.
        Like we use struct the output is limited to byte sizes ie
        (8,16,32,64)
    """
    f=open(filename, 'w')
    din_pt = din_size-din_int
    #2 complement goes from [-2**(din_size-1), 2**(din_size-1)-1]
    din = np.linspace(-2**(din_size-1), 2**(din_size-1)-1, int(2**(din_size)))/(2**din_pt)
    sig_data = expit(din)
    sig_quant = (sig_data*2**(sig_size-sig_int)).astype(int)

    dtypes=['b','h','i','q']
    ind = int(sig_size/8)-1
    dt = dtypes[ind]
    print(dt)
    if(plot):
        plt.plot(din,1.*sig_quant/2**(sig_size-sig_int))
        plt.show()
    for i in range(len(din)/2):
        data_hex = struct.pack('>'+dt, sig_quant[int(len(din)/2)+i])
        f.write(data_hex.encode('hex'))
        f.write('\n')
    for i in range(int(len(din)/2)):
        data_hex = struct.pack('>'+dt, sig_quant[i])
        f.write(data_hex.encode('hex'))
        f.write('\n')
    f.close()



parser = optparse.OptionParser()

parser.add_option('-s', '--sigmoid_size',
                    dest='sigmoid_size',
                    type='int',
                    help='sigmoid size, must be power of two')
parser.add_option('-o', '--sigmoid_int',
                    dest='sigmoid_int',
                    type='int',
                    help='sigmoid int size')
parser.add_option('-i', '--input_size',
                    dest='input_size',
                    type='int',
                    help='input size')
parser.add_option('-b', '--input_int',
                    dest='input_int',
                    type='int',
                    help='intput int size')
parser.add_option('-p','--plot',
                    dest='plot',
                    type='int',
                    help='plot the result')
parser.add_option('-f', '--filename',
                    dest='filename',
                    type='string',
                    help='filename where is stored the values')

(opt, args) = parser.parse_args()

sigmoid_gen(opt.sigmoid_size, opt.sigmoid_int, opt.input_size, opt.input_int,
            opt.filename, opt.plot)

