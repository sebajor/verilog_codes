import numpy as np
import matplotlib.pyplot as plt
import optparse, sys
sys.path.append('../')

###
### Author: Sebastian Jorquera
###

def sqrt_gen(din_width, din_pt, dout_width, dout_pt, filename, plot=0):
    """ 
    """
    f = open(filename, 'w')
    din = np.arange(2**din_width)/2.**din_pt
    sqrt = np.sqrt(din)
    sqrt_quant = (sqrt*2**dout_pt).astype(int)
    #check if there is an no representable data and saturate
    ind = (sqrt_quant>2**dout_width)
    sqrt_quant[ind] = 2**dout_width
    if(ind.any()):
        print("There is a data that is higher than 2**dout_pt, we saturated those vaues")
    if(plot):
        sqrt_unquant = sqrt_quant/2.**dout_pt
        plt.plot(din, sqrt_unquant, label='quantized')
        plt.plot(din, sqrt, label='float')
        plt.legend()
        plt.show()
    for i in range(len(din)):
        data_b = bin(sqrt_quant[i])[2:]
        f.write(data_b)
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

