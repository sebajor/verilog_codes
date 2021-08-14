import numpy as np
import matplotlib.pyplot as plt
import struct, optparse

def sqrt_gen(din_width, din_pt, dout_width, dout_pt, filename, plot=0):
    dtypes=['b','h','i','q']
    ind = int(dout_width/8)-1
    dt = dtypes[ind]
    dout_int = dout_width-dout_pt
    f = open(filename, 'w')
    din = np.arange(2**din_width)/(2.**din_pt)
    print(len(din))
    dout = np.sqrt(din)
    output = dout*2**(dout_pt)
    print(len(output))
    if (plot):
        plt.plot(din, dout, label='float')
        plt.plot(din, output/(2.**dout_pt), label='quant')
        plt.grid()
        plt.legend()
        plt.show()
    for i in range(len(output)):
        if(int(output[i])>2**(dout_width-1)-1):
            data_hex = struct.pack('>'+dt, int(0))
        else:
            data_hex = struct.pack('>'+dt,int(output[i]))
        f.write(data_hex.encode('hex'))
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
parser.add_option('-o', '--dout_width',
                    dest='dout_width',
                    type='int',
                    help='output width')
parser.add_option('-l', '--dout_pt',
                    dest='dout_pt',
                    type='int',
                    help='output bit point location')
parser.add_option('-p','--plot',
                    dest='plot',
                    type='int',
                    help='plot the result')
parser.add_option('-f', '--filename',
                    dest='filename',
                    type='string',
                    help='filename where is stored the values')


(opt, args) = parser.parse_args()

sqrt_gen(opt.din_width, opt.din_pt, opt.dout_width, opt.dout_pt, 
        opt.filename, opt.plot)

