import numpy as np
import struct
from scipy.special import expit
import matplotlib.pyplot as plt
#import ipdb

def sigmoid_gen(sig_size, sig_int, in_size, in_int, filename='sigmoid_hex.mem', plot=0):
    """ like sig lives in (-1,1) the logical thing to do is use
        sig_int=1, I would recomend in_size=5 and above that 
        saturate the data..
        The options are lying, the output is always 16bit
    """
    f = open(filename, "w")
    in_pt = in_size-in_int
    ##2 complement goes from [-2**(n-1), 2**(n-1)-1]
    din = np.linspace(-2**(in_size-1), 2**(in_size-1)-1, int(2**(in_size)))/(2**in_pt)
    sig_data = expit(din)
    sig_quant = (sig_data*2**(sig_size-sig_int)).astype(int)
    #ipdb.set_trace()

    #vhex = np.vectorize(hex)
    #data_hex = vhex(sig_quant)
    plt.plot(din,1.*sig_quant/2**(sig_size-sig_int))
    plt.savefig('quant_sigmoid')
    if(plot):
        plt.show()
    ##because of the order of 2 complemnet we divided the writing
    #write positive values first
    for i in range(len(din)/2):
        data_hex = struct.pack('>h', sig_quant[int(len(din)/2)+i])
        f.write(data_hex.encode('hex'))
        #f.write(data_hex[int(len(din)/2)+i])
        f.write('\n')
    #now the negative ones 
    for i in range(int(len(din)/2)):
        data_hex = struct.pack('>h', sig_quant[i])
        f.write(data_hex.encode('hex'))
        #f.write(data_hex[i])
        f.write('\n')
    f.close()


if __name__ == '__main__':
    sigmoid_gen(16,1,8,4,plot=1)

