import numpy as np
import struct

def two_comp_pack(values, n_bits, bin_pt):
    """ Values are a numpy array witht the actual values
        that you want to set in the dut port
        n_bits: number of bits
        n_int: integer part of the representation
    """
    n_int = n_bits-bin_pt
    quant_data = (2**bin_pt*values).astype(int)
    ovf = (quant_data>2**(n_bits-1)-1)&(quant_data<2**(n_bits-1))
    if(ovf.any()):
        raise "Cannot represent one value with that representation"
    mask = np.where(quant_data<0)
    quant_data[mask] = 2**(n_bits)+quant_data[mask]
    return quant_data

def two_comp_unpack(values, n_bits, bin_pt):
    """Values are integer values (to test if its enough to take
    get_value_signed to obtain the actual value...
    """
    n_int = n_bits-bin_pt
    mask = values>2**(n_bits-1)-1 ##negative values
    out = values.copy()
    out[mask] = values[mask]-2**n_bits
    out = 1.*out/(2**bin_pt)
    return out


if __name__=='__main__':
    f = open('w11.hex', 'w')
    np.random.seed(10)
    vals = np.random.random(64)-0.5
    vals_bin = two_comp_pack(vals, 16, 15)
    for i in range(len(vals_bin)):
        hex_val = "{0:#0{1}x}".format(vals_bin[i],6)
        f.write(hex_val)
        #f.write(hex(vals_bin[i])[:-1])
        f.write('\n')
    f.close()




