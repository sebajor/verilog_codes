import numpy as np
import matplotlib.pyplot as plt
import struct, optparse

###
### Author: Sebastian Jorquera
###

def arctan_gen(din_width, dout_width, filename='atan_rom.mem'):
    f = open(filename, 'w')
    for i in range(din_width):
        data = np.arctan(2.**(-i))/np.pi
        out = int(data*2**(dout_width-1))
        data_b = bin(int(out))[2:]
        f.write(data_b)
        f.write('\n')
    f.close()

parser = optparse.OptionParser()

parser.add_option('-i', '--din_width',
                    dest='din_width',
                    type='int',
                    help='input bitwidth, must be power of two')
parser.add_option('-o', '--dout_width',
                    dest='dout_width',
                    type='int',
                    help='output bitwidth')


(opt, args) = parser.parse_args()
arctan_gen(opt.din_width, opt.dout_width)
