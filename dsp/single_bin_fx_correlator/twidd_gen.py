import argparse
import numpy as np
import matplotlib.pyplot as plt
import sys
sys.path.append('../../cocotb_python')
from two_comp import two_comp_pack

###
### Author: Sebastian Jorquera
###


def twidd_gen(dft_size, dft_twidd, bin_width, bin_pt, filename='twidd_init.bin', plot=0):
    """
    This one assumes that the twiddle factor will be any number and the bram will be
    two times that size.
    """
    f = open(filename, 'w')
    n = np.arange(dft_size)
    data = np.exp(-1j*2*np.pi*dft_twidd/dft_size*n)
    re = data.real
    im = data.imag
    re_data = two_comp_pack(re, bin_width, bin_pt)
    im_data = two_comp_pack(im, bin_width, bin_pt)
    if(plot):
        plt.plot(re_data, label='re')
        plt.plot(im_data, label='im')
        plt.grid()
        plt.legend()
        plt.show()
    for i in range(dft_size):
        re_b = bin(int(re_data[i]))[2:]
        im_b = bin(int(im_data[i]))[2:]
        #check the order..
        f.write(im_b)
        f.write(re_b)
        f.write('\n')
    f.close()


parser = argparse.ArgumentParser()

parser.add_argument('-i', '--din_width',
                    dest='din_width',
                    type=int,
                    help='bitwidth, must be power of two')
parser.add_argument('-t', '--din_pt',
                    dest='din_pt',
                    type=int,
                    help='din bit point location')
parser.add_argument('-k', '--twidd_num',
                    dest='dft_twidd',
                    type=int,
                    help='twiddle factor number')
parser.add_argument('-n', '--dft_size',
                    dest='dft_size',
                    type=int,
                    help='dft size')
parser.add_argument('-f', '--filename',
                    type=str,
                    dest='filename',
                    help='filename where is stored the values')
parser.add_argument('-p','--plot',
                    dest='plot',
                    action="store_true",
                    help='plot the result')

if __name__ == '__main__':
    opt  = parser.parse_args()
    twidd_gen(opt.dft_size, opt.dft_twidd, opt.din_width, opt.din_pt, 
            filename=str(opt.filename), plot=opt.plot)

